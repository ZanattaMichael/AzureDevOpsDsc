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

# Always reload Enums+Classes into this file's own scope. Pester rebinds each test/block's
# session state for isolation, which can leave classes loaded elsewhere (e.g. by the
# orchestrator above) unresolvable - causing intermittent "Could not find type [X]" failures.
$RepositoryRoot = (Get-Item -Path $PSScriptRoot).Parent.Parent.Parent.Parent.FullName
. "$RepositoryRoot\tests\Unit\Modules\TestHelpers\Import-ClassesAndEnums.ps1" -RepositoryRoot $RepositoryRoot

Describe 'AzDoGroupMember' -Tag "Unit", "Resources" {

    BeforeAll {
        $ENV:AZDODSC_CACHE_DIRECTORY = 'mocked_cache_directory'

        Mock -CommandName Import-Module
        Mock -CommandName Test-Path -MockWith { $true }
        Mock -CommandName Import-Clixml -MockWith {
            return @{
                OrganizationName = 'mock-org'
                Token = @{
                    tokenType = 'ManagedIdentity'
                    access_token = 'mock_access_token'
                }

            }
        }
        Mock -CommandName New-AzDoAuthenticationProvider
        Mock -CommandName Get-AzDoCacheObjects -MockWith {
            return @('mock-cache-type')
        }
        Mock -CommandName Initialize-CacheObject

    }
    AfterAll {

        $ENV:AZDODSC_CACHE_DIRECTORY = $null

    }

    Context 'When getting the current state of group members' {

        BeforeAll {
            Mock -CommandName Get-AzDoGroupMember -MockWith {
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
