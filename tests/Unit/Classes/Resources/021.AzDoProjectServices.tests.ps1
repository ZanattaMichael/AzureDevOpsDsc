# Requires -Module Pester -Version 5.0.0
# Requires -Module DscResource.Common

if ($null -eq $Global:ClassesLoaded)
{
    $RepositoryRoot = (Get-Item -Path $PSScriptRoot).Parent.Parent.Parent.Parent.FullName
    . "$RepositoryRoot\azuredevopsdsc.tests.ps1" -LoadModulesOnly
}


# Always reload Enums+Classes into this file's own scope. Pester rebinds each test/block's
# session state for isolation, which can leave classes loaded elsewhere (e.g. by the
# orchestrator above) unresolvable - causing intermittent "Could not find type [X]" failures.
$RepositoryRoot = (Get-Item -Path $PSScriptRoot).Parent.Parent.Parent.Parent.FullName
. "$RepositoryRoot\tests\Unit\Modules\TestHelpers\Import-ClassesAndEnums.ps1" -RepositoryRoot $RepositoryRoot

Describe 'AzDoProjectServices Class' -Tag "Unit", "Resources" {

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

        It 'Should initialize with default service values' {
            $resource = [AzDoProjectServices]::new()

            $resource.GitRepositories | Should -Be 'Enabled'
            $resource.WorkBoards      | Should -Be 'Enabled'
            $resource.BuildPipelines  | Should -Be 'Enabled'
            $resource.TestPlans       | Should -Be 'Enabled'
            $resource.AzureArtifact   | Should -Be 'Enabled'
        }
    }

    Context 'Property Assignment' {

        It 'Should accept Enabled and Disabled values for GitRepositories' {
            $resource = [AzDoProjectServices]::new()
            { $resource.GitRepositories = 'Enabled'  } | Should -Not -Throw
            { $resource.GitRepositories = 'Disabled' } | Should -Not -Throw
        }

        It 'Should reject invalid values for GitRepositories' {
            $resource = [AzDoProjectServices]::new()
            { $resource.GitRepositories = 'InvalidValue' } | Should -Throw
        }

        It 'Should accept Enabled and Disabled for all service properties' {
            $resource = [AzDoProjectServices]::new()
            { $resource.WorkBoards     = 'Disabled' } | Should -Not -Throw
            { $resource.BuildPipelines = 'Disabled' } | Should -Not -Throw
            { $resource.TestPlans      = 'Disabled' } | Should -Not -Throw
            { $resource.AzureArtifact  = 'Disabled' } | Should -Not -Throw
        }

        It 'Should set ProjectName' {
            $resource = [AzDoProjectServices]::new()
            $resource.ProjectName = 'TestProject'
            $resource.ProjectName | Should -Be 'TestProject'
        }
    }

    Context 'Get Method' {

        BeforeAll {
            Mock -CommandName Get-AzDoProjectServices -MockWith {
                return @{
                    Ensure            = [Ensure]::Present
                    ProjectName       = 'MyProject'
                    GitRepositories   = 'Enabled'
                    WorkBoards        = 'Enabled'
                    BuildPipelines    = 'Disabled'
                    TestPlans         = 'Disabled'
                    AzureArtifact     = 'Enabled'
                    propertiesChanged = @()
                    status            = $null
                }
            }
        }

        It 'Should return an instance of AzDoProjectServices' {
            $resource = [AzDoProjectServices]::new()
            $resource.ProjectName = 'MyProject'
            $result = $resource.Get()

            $result | Should -BeOfType 'AzDoProjectServices'
        }

        It 'Should return ProjectName from Get-AzDoProjectServices' {
            $resource = [AzDoProjectServices]::new()
            $resource.ProjectName = 'MyProject'
            $result = $resource.Get()

            $result.ProjectName | Should -Be 'MyProject'
        }
    }
}
