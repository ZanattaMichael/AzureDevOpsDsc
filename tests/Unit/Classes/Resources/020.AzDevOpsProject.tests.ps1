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

Describe 'AzDevOpsProject' {
    # Mocking AzDevOpsDscResourceBase class since it's not provided
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

    Context 'Constructor' {
        It 'should initialize properties correctly when given valid parameters' {
            $project = [AzDevOpsProject]::new()
            $project.ProjectId = "12345"
            $project.ProjectName = "TestProject"
            $project.ProjectDescription = "This is a test project"
            $project.SourceControlType = "Git"

            $project.ProjectId | Should -Be "12345"
            $project.ProjectName | Should -Be "TestProject"
            $project.ProjectDescription | Should -Be "This is a test project"
            $project.SourceControlType | Should -Be "Git"
        }
    }

    Context 'GetDscResourcePropertyNamesWithNoSetSupport Method' {
        It 'should return SourceControlType as property with no set support' {
            $project = [AzDevOpsProject]::new()
            $result = $project.GetDscResourcePropertyNamesWithNoSetSupport()

            $result | Should -Contain "SourceControlType"
        }
    }

    Context 'GetDscCurrentStateProperties Method' {

        It 'should return correct properties when CurrentResourceObject is not null' {
            $project = [AzDevOpsProject]::new()
            $currentResourceObject = [PSCustomObject]@{
                id = "12345"
                name = "TestProject"
                description = "This is a test project"
                capabilities = @{
                    versioncontrol = @{
                        sourceControlType = "Git"
                    }
                }
            }

            $result = $project.GetDscCurrentStateProperties($currentResourceObject)

            $result.ProjectId | Should -Be "12345"
            $result.ProjectName | Should -Be "TestProject"
            $result.ProjectDescription | Should -Be "This is a test project"
            $result.SourceControlType | Should -Be "Git"
            $result.Ensure | Should -Be "Present"
        }
    }
}
