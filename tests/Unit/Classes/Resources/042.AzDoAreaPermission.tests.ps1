# Requires -Module Pester -Version 5.0.0
# Requires -Module DscResource.Common

if ($null -eq $Global:ClassesLoaded)
{
    $RepositoryRoot = (Get-Item -Path $PSScriptRoot).Parent.Parent.Parent.Parent.FullName
    . "$RepositoryRoot\azuredevopsdsc.tests.ps1" -LoadModulesOnly
}

Describe 'AzDoAreaPermission Class' -Tag "Unit", "Resources" {

    BeforeAll {

        $ENV:AZDODSC_CACHE_DIRECTORY = 'mocked_cache_directory'

        Mock -CommandName Import-Module
        Mock -CommandName Test-Path -MockWith { $true }
        Mock -CommandName Import-Clixml -MockWith {
            return @{
                OrganizationName = 'mock-org'
                Token = @{
                    tokenType    = 'ManagedIdentity'
                    access_token = 'mock_access_token'
                }
            }
        }
        Mock -CommandName New-AzDoAuthenticationProvider
        Mock -CommandName Get-AzDoCacheObjects -MockWith { return @('mock-cache-type') }
        Mock -CommandName Initialize-CacheObject
    }

    AfterAll {
        $ENV:AZDODSC_CACHE_DIRECTORY = $null
    }

    Context 'Initialization' {

        It 'Should initialize with default values' {
            $resource = [AzDoAreaPermission]::new()

            $resource.isInherited | Should -Be $true
            $resource.AreaPath    | Should -BeNullOrEmpty
        }
    }

    Context 'Property Assignment' {

        It 'Should set ProjectName' {
            $resource = [AzDoAreaPermission]::new()
            $resource.ProjectName = 'TestProject'
            $resource.ProjectName | Should -Be 'TestProject'
        }

        It 'Should set AreaPath' {
            $resource = [AzDoAreaPermission]::new()
            $resource.AreaPath = 'TestProject\Area\SubArea'
            $resource.AreaPath | Should -Be 'TestProject\Area\SubArea'
        }

        It 'Should set isInherited to false' {
            $resource = [AzDoAreaPermission]::new()
            $resource.isInherited = $false
            $resource.isInherited | Should -Be $false
        }

        It 'Should set Permissions hashtable array' {
            $resource = [AzDoAreaPermission]::new()
            $resource.Permissions = @(
                @{ Identity = 'User1'; Permission = @{ Read = 'Allow' } }
            )
            $resource.Permissions.Count | Should -Be 1
        }
    }

    Context 'Get Method' {

        BeforeAll {
            Mock -CommandName Get-AzDoAreaPermission -MockWith {
                return @{
                    Ensure            = [Ensure]::Present
                    project           = 'MyProject'
                    areaPath          = 'MyProject\Area\SubArea'
                    isInherited       = $false
                    Permissions       = @()
                    propertiesChanged = @()
                    status            = $null
                }
            }
        }

        It 'Should return an instance of AzDoAreaPermission' {
            $resource = [AzDoAreaPermission]::new()
            $resource.ProjectName = 'MyProject'
            $resource.AreaPath    = 'MyProject\Area\SubArea'
            $resource.isInherited = $false

            $result = $resource.Get()
            $result | Should -BeOfType 'AzDoAreaPermission'
        }

        It 'Should return ProjectName from Get-AzDoAreaPermission' {
            $resource = [AzDoAreaPermission]::new()
            $resource.ProjectName = 'MyProject'
            $result = $resource.Get()

            $result.ProjectName | Should -Be 'MyProject'
        }
    }
}
