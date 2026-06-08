# Requires -Module Pester -Version 5.0.0
# Requires -Module DscResource.Common

if ($null -eq $Global:ClassesLoaded)
{
    $RepositoryRoot = (Get-Item -Path $PSScriptRoot).Parent.Parent.Parent.Parent.FullName
    . "$RepositoryRoot\azuredevopsdsc.tests.ps1" -LoadModulesOnly
}

Describe 'AzDoIterationPermission Class' {

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
            $resource = [AzDoIterationPermission]::new()

            $resource.isInherited    | Should -Be $true
            $resource.IterationPath  | Should -BeNullOrEmpty
        }
    }

    Context 'Property Assignment' {

        It 'Should set ProjectName' {
            $resource = [AzDoIterationPermission]::new()
            $resource.ProjectName = 'TestProject'
            $resource.ProjectName | Should -Be 'TestProject'
        }

        It 'Should set IterationPath' {
            $resource = [AzDoIterationPermission]::new()
            $resource.IterationPath = 'TestProject\Iteration\Sprint1'
            $resource.IterationPath | Should -Be 'TestProject\Iteration\Sprint1'
        }

        It 'Should set isInherited to false' {
            $resource = [AzDoIterationPermission]::new()
            $resource.isInherited = $false
            $resource.isInherited | Should -Be $false
        }

        It 'Should set Permissions hashtable array' {
            $resource = [AzDoIterationPermission]::new()
            $resource.Permissions = @(
                @{ Identity = 'User1'; Permission = @{ Read = 'Allow' } }
                @{ Identity = 'User2'; Permission = @{ Write = 'Deny' } }
            )
            $resource.Permissions.Count | Should -Be 2
        }
    }

    Context 'Get Method' {

        BeforeAll {
            Mock -CommandName Get-AzDoIterationPermission -MockWith {
                return @{
                    Ensure            = [Ensure]::Present
                    project           = 'MyProject'
                    iterationPath     = 'MyProject\Iteration\Sprint1'
                    isInherited       = $false
                    Permissions       = @()
                    propertiesChanged = @()
                    status            = $null
                }
            }
        }

        It 'Should return an instance of AzDoIterationPermission' {
            $resource = [AzDoIterationPermission]::new()
            $resource.ProjectName   = 'MyProject'
            $resource.IterationPath = 'MyProject\Iteration\Sprint1'
            $resource.isInherited   = $false

            $result = $resource.Get()
            $result | Should -BeOfType 'AzDoIterationPermission'
        }

        It 'Should return ProjectName from Get-AzDoIterationPermission' {
            $resource = [AzDoIterationPermission]::new()
            $resource.ProjectName = 'MyProject'
            $result = $resource.Get()

            $result.ProjectName | Should -Be 'MyProject'
        }
    }
}
