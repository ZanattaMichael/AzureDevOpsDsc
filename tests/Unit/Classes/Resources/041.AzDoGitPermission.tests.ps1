# Requires -Module Pester -Version 5.0.0
# Requires -Module DscResource.Common

# Test if the class is defined
if ($Global:ClassesLoaded -eq $null)
{
    # Attempt to find the root of the repository
    $RepositoryRoot = (Get-Item -Path $PSScriptRoot).Parent.Parent.Parent.Parent.FullName
    # Load the classes
    $preInitialize = Get-ChildItem -Path "$RepositoryRoot" -Recurse -Filter '*.ps1' | Where-Object { $_.Name -eq 'Classes.BeforeAll.ps1' }
    . $preInitialize.FullName -RepositoryPath $RepositoryRoot
}

Describe 'AzDoGitPermission' {

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


    Context 'When getting the current state of Git permissions' {
        It 'Should return the current state properties' {
            # Arrange
            $gitPermission = [AzDoGitPermission]::new()
            $gitPermission.ProjectName = "MyProject"
            $gitPermission.RepositoryName = "MyRepository"

            # Act
            $currentState = $gitPermission.Get()

            # Assert
            $currentState.ProjectName | Should -Be "MyProject"
            $currentState.RepositoryName | Should -Be "MyRepository"
            $currentState.isInherited | Should -Be $true
            $currentState.Permissions | Should -Be @('Read', 'Contribute')
        }
    }
}
