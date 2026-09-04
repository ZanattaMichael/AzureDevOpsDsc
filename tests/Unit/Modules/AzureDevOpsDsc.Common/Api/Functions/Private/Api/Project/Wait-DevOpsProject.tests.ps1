$currentFile = $MyInvocation.MyCommand.Path

Describe "Wait-DevOpsProject" -Tag "Unit", "Project", "API" {

    BeforeAll {

        # Load the functions to test
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Wait-DevOpsProject.tests.ps1'
        }

        # Load the functions to test
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) {
            . $file.FullName
        }

        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
            return @{ status = 'wellFormed' }
        }

        Mock -CommandName Write-Error

        # Otherwise the timeout context below really sleeps for its ten attempts.
        Mock -CommandName Start-Sleep

    }

    Context "When project is created successfully" {

        It "Should detect the project has been created successfully and exit the loop" {
            $organizationName = "TestOrg"
            $projectURL = "https://dev.azure.com/TestOrg/TestProject"
            $apiVersion = "6.0"

            $params = @{
                OrganizationName = $organizationName
                ProjectURL       = $projectURL
                ApiVersion       = $apiVersion
            }

            { Wait-DevOpsProject @params } | Should -Not -Throw

            # One poll, and no spurious timeout: 'wellFormed' is terminal.
            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Exactly -Times 1
            Assert-MockCalled -CommandName Write-Error -Exactly -Times 0
        }
    }

    Context "When the operations endpoint reports success" {
        BeforeAll {
            # Both callers poll an operation reference, not the project, so 'succeeded'
            # - not 'wellFormed' - is what the terminal success case actually looks like
            # in production.
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
                return @{ status = 'succeeded' }
            }
        }

        It "Should treat 'succeeded' as terminal and exit after a single poll" {
            $params = @{
                OrganizationName = "TestOrg"
                ProjectURL       = "https://dev.azure.com/TestOrg/_apis/operations/00000000-0000-0000-0000-000000000000"
                ApiVersion       = "6.0"
            }

            { Wait-DevOpsProject @params } | Should -Not -Throw

            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Exactly -Times 1
            Assert-MockCalled -CommandName Write-Error -Exactly -Times 0
        }
    }

    Context "When the operation is still queued" {
        BeforeAll {
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
                return @{ status = 'inProgress' }
            }
        }

        It "Should keep polling and time out rather than returning early" {
            $params = @{
                OrganizationName = "TestOrg"
                ProjectURL       = "https://dev.azure.com/TestOrg/_apis/operations/00000000-0000-0000-0000-000000000000"
                ApiVersion       = "6.0"
            }

            { Wait-DevOpsProject @params } | Should -Not -Throw

            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Exactly -Times 10
            Assert-MockCalled -CommandName Write-Error -Exactly -Times 1
        }
    }

    Context "When the operation is cancelled" {
        BeforeAll {
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
                return @{ status = 'cancelled' }
            }
        }

        It "Should treat 'cancelled' as a terminal failure" {
            $params = @{
                OrganizationName = "TestOrg"
                ProjectURL       = "https://dev.azure.com/TestOrg/_apis/operations/00000000-0000-0000-0000-000000000000"
                ApiVersion       = "6.0"
            }

            { Wait-DevOpsProject @params } | Should -Not -Throw

            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Exactly -Times 1
            Assert-MockCalled -CommandName Write-Error -Exactly -Times 1
        }
    }

    Context "When project creation fails" {
        BeforeAll {
            # In Pester 5 a Mock sitting directly in a Context body runs during discovery
            # and never takes effect, so these contexts used to run against the
            # 'wellFormed' mock above and only passed because the timeout error fired
            # unconditionally. Put them in BeforeAll so they actually apply.
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
                return @{ status = 'failed'; message = 'Creation failed' }
            }
        }

        It "Should detect the failure and write an error message" {
            $organizationName = "TestOrg"
            $projectURL = "https://dev.azure.com/TestOrg/TestProject"
            $apiVersion = "6.0"

            $params = @{
                OrganizationName = $organizationName
                ProjectURL       = $projectURL
                ApiVersion       = $apiVersion
            }

            { Wait-DevOpsProject @params } | Should -Not -Throw

            Assert-MockCalled -CommandName Write-Error
        }
    }

    Context "When project creation times out" {
        BeforeAll {
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
                return @{ status = 'creating' }
            }
        }

        It "Should time out after 10 attempts and write an error message" {
            $organizationName = "TestOrg"
            $projectURL = "https://dev.azure.com/TestOrg/TestProject"
            $apiVersion = "6.0"

            $params = @{
                OrganizationName = $organizationName
                ProjectURL       = $projectURL
                ApiVersion       = $apiVersion
            }

            { Wait-DevOpsProject @params } | Should -Not -Throw

            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Exactly -Times 10
            Assert-MockCalled -CommandName Write-Error -Exactly -Times 1
        }
    }

    Context "When project creation status is not set" {
        BeforeAll {
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
                return @{ status = 'notSet'; message = 'Status not set' }
            }
        }

        It "Should detect the status is not set and write an error message" {

            $organizationName = "TestOrg"
            $projectURL = "https://dev.azure.com/TestOrg/TestProject"
            $apiVersion = "6.0"

            $params = @{
                OrganizationName = $organizationName
                ProjectURL       = $projectURL
                ApiVersion       = $apiVersion
            }

            { Wait-DevOpsProject @params } | Should -Not -Throw

            Assert-MockCalled -CommandName Write-Error
        }
    }
}
