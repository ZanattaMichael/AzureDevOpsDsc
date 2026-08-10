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

Describe 'AzDoOrganizationGroup' -Tag "Unit", "Resources" {

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

    Context 'Constructor' {
        It 'should initialize properties correctly when given valid parameters' {
            $organizationGroup = [AzDoOrganizationGroup]::new()
            $organizationGroup.GroupName = "MyGroup"
            $organizationGroup.GroupDescription = "This is my group."

            $organizationGroup.GroupName | Should -Be "MyGroup"
            $organizationGroup.GroupDescription | Should -Be "This is my group."
        }
    }

    Context 'GetDscResourcePropertyNamesWithNoSetSupport Method' {
        It 'should return an empty array' {
            $organizationGroup = [AzDoOrganizationGroup]::new()

            $result = $organizationGroup.GetDscResourcePropertyNamesWithNoSetSupport()

            $result | Should -Be @()
        }
    }

    Context 'GetDscCurrentStateProperties Method' {
        It 'should return properties with Ensure set to Absent if CurrentResourceObject is null' {
            $organizationGroup = [AzDoOrganizationGroup]::new()

            $result = $organizationGroup.GetDscCurrentStateProperties($null)

            $result.Ensure | Should -Be 'Absent'
        }

        It 'should return current state properties from CurrentResourceObject' {
            $organizationGroup = [AzDoOrganizationGroup]::new()
            $currentResourceObject = [PSCustomObject]@{
                GroupName = "MyGroup"
                GroupDescription = "This is my group"
                Ensure = "Present"
                LookupResult = @{ Status = "Found" }
            }

            $result = $organizationGroup.GetDscCurrentStateProperties($currentResourceObject)

            $result.GroupName | Should -Be "MyGroup"
            $result.GroupDescription | Should -Be "This is my group"
            $result.Ensure | Should -Be "Present"
            $result.LookupResult.Status | Should -Be "Found"
        }
    }
}
