$currentFile = $MyInvocation.MyCommand.Path

Describe "Set-AzDoProjectServices" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-AzDoProjectServices.tests.ps1'
        }

        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) { . $file.FullName }

        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }
        Mock -CommandName Get-CacheItem -MockWith { return @{ id = 'proj-id'; name = 'TestProject' } }
        Mock -CommandName Set-ProjectServiceStatus
        Mock -CommandName Write-Warning
    }

    Context "when LookupResult has propertiesChanged" {
        It "calls Set-ProjectServiceStatus for each changed property" {
            $lookupResult = @{
                LiveServices = @{
                    Repos = @{ state = 'Disabled'; featureId = 'feature-repos' }
                }
                propertiesChanged = @(
                    @{ Expected = 'Enabled'; FeatureId = 'feature-repos' }
                )
            }
            Set-AzDoProjectServices -ProjectName 'TestProject' -LookupResult $lookupResult
            Assert-MockCalled -CommandName Set-ProjectServiceStatus -Exactly -Times 1
        }
    }

    Context "when LookupResult has no propertiesChanged" {
        It "does not call Set-ProjectServiceStatus" {
            $lookupResult = @{
                LiveServices      = @{}
                propertiesChanged = @()
            }
            Set-AzDoProjectServices -ProjectName 'TestProject' -LookupResult $lookupResult
            Assert-MockCalled -CommandName Set-ProjectServiceStatus -Times 0
        }
    }
}
