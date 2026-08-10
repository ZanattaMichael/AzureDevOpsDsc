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

Describe 'AzDoGroupMember' -Tag "Unit", "Resources" {

    BeforeAll {
        $ENV:AZDODSC_CACHE_DIRECTORY = 'mocked_cache_directory'

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

    }
    AfterAll {

        $ENV:AZDODSC_CACHE_DIRECTORY = $null

    }

    Context 'When getting the current state of group members' {

        BeforeAll {
            Mock -CommandName Get-AzDoGroupMember -ModuleName AzureDevOpsDsc -MockWith {
                return @{
                    Ensure = [Ensure]::Absent
                    propertiesChanged = @()
                    GroupName = "MyGroup"
                    GroupMembers = @("User1", "User2")
                }
            }
        }

        It 'Should return the current state properties' {
            # Arrange
            $groupMember = [AzDoGroupMember]::new()
            $groupMember.GroupName = "MyGroup"
            $groupMember.GroupMembers = @("User1", "User2")

            # Act
            $currentState = $groupMember.Get()

            # Assert
            $currentState.GroupName | Should -Be "MyGroup"
            $currentState.GroupMembers | Should -Be @("User1", "User2")
        }
    }
}
