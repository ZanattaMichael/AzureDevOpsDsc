$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzDoProjectServices" {

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
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
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
