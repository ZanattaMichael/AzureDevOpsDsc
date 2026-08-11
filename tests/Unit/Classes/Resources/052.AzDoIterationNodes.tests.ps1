using module AzureDevOpsDscNative

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

Describe 'AzDoIterationNodes Tests' -Tag "Unit", "Resources" {


    BeforeAll {

        $ENV:AZDODSC_CACHE_DIRECTORY = 'mocked_cache_directory'

        $TestProjectNameFunctionpath = Get-FunctionItem 'Test-AzDevOpsProjectName.ps1'
        . $TestProjectNameFunctionpath

        Mock -CommandName Import-Module -ModuleName AzureDevOpsDscNative
        Mock -CommandName Test-Path -ModuleName AzureDevOpsDscNative -MockWith { $true }
        Mock -CommandName Import-Clixml -ModuleName AzureDevOpsDscNative -MockWith {
            return @{
                OrganizationName = 'mock-org'
                Token = @{
                    tokenType = 'ManagedIdentity'
                    access_token = 'mock_access_token'
                }

            }
        }
        Mock -CommandName New-AzDoAuthenticationProvider -ModuleName AzureDevOpsDscNative
        Mock -CommandName Get-AzDoCacheObjects -ModuleName AzureDevOpsDscNative -MockWith {
            return @('mock-cache-type')
        }

        Mock -CommandName Initialize-CacheObject -ModuleName AzureDevOpsDscNative
        Mock -CommandName Test-AzDevOpsProjectName -ModuleName AzureDevOpsDsc.Common -MockWith { return $true }

    }

    AfterAll {

        $ENV:AZDODSC_CACHE_DIRECTORY = $null

    }

    Context 'When getting the current state' {


        [DscProperty(Key, Mandatory)]
        [Alias('Name')]
        [System.String]$ProjectName

        [DscProperty()]
        [Alias('Path')]
        [System.String[]]$AreaPaths

        BeforeAll {
            Mock -CommandName Get-AzDoIterationNodes -ModuleName AzureDevOpsDscNative -MockWith {
                return @{
                    Ensure = [Ensure]::Absent
                    propertiesChanged = @()
                    ProjectName = "MyProject"
                    IterationAttributes = @(
                        @{
                            Path = 'Iteration2/SubIteration'
                            StartDate = '2023-02-01'
                            EndDate = '2023-02-28'
                        }
                        @{
                            Path = 'Iteration1'
                            StartDate = '2023-01-01'
                            EndDate = '2023-01-31'
                        }
                    )
                    LookupResult = @{
                        Value = 1
                    }
                }
            }
        }

        It 'Should return the current state properties' {
            # Arrange
            $object = [AzDoIterationNodes]::new()
            $object.ProjectName = "MyProject"
            $object.IterationAttributes = @(
                @{
                    Path = 'Iteration1'
                    StartDate = '2023-01-01'
                    EndDate = '2023-01-31'
                }
                @{
                    Path = 'Iteration2/SubIteration'
                    StartDate = '2023-02-01'
                    EndDate = '2023-02-28'
                }
            )

            # Act
            $currentState = $object.Get()

            # Assert
            $currentState.ProjectName | Should -Be "MyProject"
            $currentState.IterationAttributes = @(
                @{
                    Path = 'Iteration1'
                    StartDate = '2023-01-01'
                    EndDate = '2023-01-31'
                }
                @{
                    Path = 'Iteration2/SubIteration'
                    StartDate = '2023-02-01'
                    EndDate = '2023-02-28'
                }
            )
        }
    }
}
