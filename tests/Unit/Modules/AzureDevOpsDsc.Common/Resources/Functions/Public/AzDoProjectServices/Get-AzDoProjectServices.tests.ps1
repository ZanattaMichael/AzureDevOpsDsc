$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzDoProjectServices" -Tag "Unit", "ProjectServices" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoProjectServices.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-ClassFilePath '003.LocalizedDataAzURLParams')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')
        . (Get-FunctionItem 'Resolve-AzDoProject.ps1')

        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        # AUTO-ADDED live-fallback mocks (unit isolation for cache-miss live lookups)
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { return $null }
    }

    Context "when project is not found in cache" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
            Mock -CommandName Write-Warning
        }

        It "returns status NotFound" {
            $result = Get-AzDoProjectServices -ProjectName 'NonExistent'
            $result.status | Should -Be 'NotFound'
        }

        It "returns status NotFound when the live lookup answers 404" {
            # #55: a missing project used to surface as a TF200016 error from Get.
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
                throw 'Response status code does not indicate success: 404 (Not Found). TF200016: The following project does not exist: NonExistent.'
            }

            $result = Get-AzDoProjectServices -ProjectName 'NonExistent'
            $result.status | Should -Be 'NotFound'
        }

        It "rethrows a live lookup failure other than 404" {
            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
                throw 'Response status code does not indicate success: 500 (Internal Server Error).'
            }

            { Get-AzDoProjectServices -ProjectName 'NonExistent' } | Should -Throw '*500*'
        }
    }

    Context "when project is found and all services match desired state" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return @{ id = 'proj-id'; name = 'TestProject' } }
            Mock -CommandName Get-ProjectServiceStatus -MockWith { return @{ state = 'Enabled'; featureId = 'feature-id' } }
        }

        It "returns status Unchanged when all services match defaults (Enabled)" {
            $result = Get-AzDoProjectServices -ProjectName 'TestProject'
            $result.status | Should -Be 'Unchanged'
        }

        It "populates LiveServices in the result" {
            $result = Get-AzDoProjectServices -ProjectName 'TestProject'
            $result.LiveServices | Should -Not -BeNullOrEmpty
        }
    }

    Context "when a service state differs from desired" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return @{ id = 'proj-id'; name = 'TestProject' } }
            $script:callCount = 0
            Mock -CommandName Get-ProjectServiceStatus -MockWith {
                $script:callCount++
                if ($script:callCount -eq 1) {
                    return @{ state = 'Disabled'; featureId = 'feature-id' }
                }
                return @{ state = 'Enabled'; featureId = 'feature-id' }
            }
        }

        It "returns status Changed when GitRepositories is Disabled but desired Enabled" {
            $result = Get-AzDoProjectServices -ProjectName 'TestProject' -GitRepositories 'Enabled'
            $result.status | Should -Be 'Changed'
        }

        It "populates propertiesChanged" {
            $result = Get-AzDoProjectServices -ProjectName 'TestProject' -GitRepositories 'Enabled'
            $result.propertiesChanged | Should -Not -BeNullOrEmpty
        }
    }
}
