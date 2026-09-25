$currentFile = $MyInvocation.MyCommand.Path

Describe 'Set-GitRepository Tests' -Tag "Unit", "GitRepository", "API" {

    BeforeAll {

        # Load the functions to test
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-GitRepository.tests.ps1'
        }

        # Load the functions to test
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) {
            . $file.FullName
        }

        Mock -CommandName Invoke-AzDevOpsApiRestMethod

    }

    Context 'When disabling a repository' {

        It 'should PATCH the repository with isDisabled = true' {
            $mockProject = [PSCustomObject]@{ name = 'TestProject'; id = '12345' }
            $mockRepo    = [PSCustomObject]@{ name = 'TestRepo'; id = 'repo-id' }

            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
                [PSCustomObject]@{ name = 'TestRepo'; id = 'repo-id'; isDisabled = $true }
            } -ParameterFilter {
                ($ApiUri -match [regex]::Escape('/TestProject/_apis/git/repositories/repo-id')) -and
                ($Method -eq 'PATCH') -and
                ($Body -match '"isDisabled":\s*true')
            }

            $result = Set-GitRepository -ApiUri "https://dev.azure.com/org" -Project $mockProject -Repository $mockRepo -IsDisabled $true -ApiVersion '7.1'

            Assert-MockCalled Invoke-AzDevOpsApiRestMethod -Exactly 1
            $result.isDisabled | Should -Be $true
        }
    }

    Context 'When re-enabling a repository' {

        It 'should PATCH the repository with isDisabled = false' {
            $mockProject = [PSCustomObject]@{ name = 'TestProject'; id = '12345' }
            $mockRepo    = [PSCustomObject]@{ name = 'TestRepo'; id = 'repo-id' }

            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
                [PSCustomObject]@{ name = 'TestRepo'; id = 'repo-id'; isDisabled = $false }
            } -ParameterFilter {
                $Body -match '"isDisabled":\s*false'
            }

            $result = Set-GitRepository -ApiUri "https://dev.azure.com/org" -Project $mockProject -Repository $mockRepo -IsDisabled $false -ApiVersion '7.1'

            Assert-MockCalled Invoke-AzDevOpsApiRestMethod -Exactly 1
            $result.isDisabled | Should -Be $false
        }
    }

    Context 'When failing to update a repository' {

        It 'should write an error message and not throw' {
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { throw "Boom" }
            Mock -CommandName Write-Error -Verifiable

            { Set-GitRepository -ApiUri "https://dev.azure.com/org" -Project ([PSCustomObject]@{ name = 'TestProject' }) -Repository ([PSCustomObject]@{ id = 'repo-id' }) -IsDisabled $true -ApiVersion '7.1' } | Should -Not -Throw

            Assert-VerifiableMock
        }
    }
}
