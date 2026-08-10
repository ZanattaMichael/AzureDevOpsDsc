using module AzureDevOpsDsc

# Requires -Module Pester -Version 5.0.0
# Requires -Module DscResource.Common

# Test if the class is defined
if ($null -eq $Global:ClassesLoaded)
{
    # Attempt to find the root of the repository
    $RepositoryRoot = (Get-Item -Path $PSScriptRoot).Parent.Parent.Parent.Parent.FullName
    # Load the Dependencies
    . "$RepositoryRoot\azuredevopsdsc.tests.ps1" -LoadModulesOnly
}

Describe 'AzDoWIPTags Tests' -Tag "Unit", "Resources" {

    BeforeAll {

        $ENV:AZDODSC_CACHE_DIRECTORY = 'mocked_cache_directory'

        $TestProjectNameFunctionpath = Get-FunctionItem 'Test-AzDevOpsProjectName.ps1'
        . $TestProjectNameFunctionpath

        Mock -CommandName Import-Module -ModuleName AzureDevOpsDsc
        Mock -CommandName Test-Path -ModuleName AzureDevOpsDsc -MockWith { $true }
        Mock -CommandName Import-Clixml -ModuleName AzureDevOpsDsc -MockWith {
            return @{
                OrganizationName = 'mock-org'
                Token = @{
                    tokenType = 'ManagedIdentity'
                    access_token = 'mock_access_token'
                }

            }
        }
        Mock -CommandName New-AzDoAuthenticationProvider -ModuleName AzureDevOpsDsc
        Mock -CommandName Get-AzDoCacheObjects -ModuleName AzureDevOpsDsc -MockWith {
            return @('mock-cache-type')
        }

        Mock -CommandName Initialize-CacheObject -ModuleName AzureDevOpsDsc
        Mock -CommandName Test-AzDevOpsProjectName -ModuleName AzureDevOpsDsc -MockWith { return $true }

    }

    AfterAll {

        $ENV:AZDODSC_CACHE_DIRECTORY = $null

    }

    Context 'When getting the current state' {

        BeforeAll {
            Mock -CommandName Get-AzDoWIPTags -ModuleName AzureDevOpsDsc -MockWith {
                return @{
                    Ensure = [Ensure]::Absent
                    propertiesChanged = @()
                    ProjectName = "MyProject"
                    WorkItemTrackingTagList = @('Tag1', 'Tag2')
                    LookupResult = @{
                        Value = 1
                    }
                }
            }
        }

        It 'Should return the current state properties' {
            # Arrange
            $object = [AzDoWIPTags]::new()
            $object.ProjectName = "MyProject"
            $object.WorkItemTrackingTagList = @('Tag1', 'Tag2', 'Tag3')

            # Act
            $currentState = $object.Get()

            # Assert
            $currentState.ProjectName | Should -Be "MyProject"
            $currentState.WorkItemTrackingTagList = @('Tag1', 'Tag2')
        }
    }
}
