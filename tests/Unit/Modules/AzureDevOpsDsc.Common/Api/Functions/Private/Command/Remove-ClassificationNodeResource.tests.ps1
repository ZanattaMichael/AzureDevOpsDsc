$currentFile = $MyInvocation.MyCommand.Path

Describe 'Remove-ClassificationNodeResource Tests' -Tags "Unit", "Cache" {

    BeforeAll {

        # Set the Project
        $null = Set-Variable -Name "AzDoProject" -Value @() -Scope Global

        # Load the functions to test
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Remove-ClassificationNodeResource.tests.ps1'
        }

        # Load the functions to test
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) {
            . $file.FullName
        }

        # Load Get-AzDoCacheObjects
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        # Mocking auxiliary functions
        Mock -CommandName Remove-ClassificationNode
        Mock -CommandName Remove-CacheItem
        Mock -CommandName Set-CacheObject
        Mock -CommandName Refresh-CacheObject
        Mock -CommandName Get-Variable -MockWith { return 'mockValue' }

        # Sample LookupResult for testing
        $lookupResult = @{
            propertiesChanged = @{
                ToRemove = @(
                    @{ Path = "MyProject/Iteration/Sprint1" },
                    @{ Path = "MyProject/Area/Feature1" }
                )
            }
            cachedAreaNodes = @(
                @{ path = "\MyProject\Area"; id = 456 }
            )
        }

    }

    Context 'When removing Iteration nodes' {

        It 'Should remove iteration nodes and update cache' {
            # Act
            Remove-ClassificationNodeResource -ProjectName "MyProject" -NodeType "Iterations" -LookupResult $lookupResult -OrganizationName "TestOrg"

            # Assert
            Assert-MockCalled -CommandName Remove-ClassificationNode -Exactly 2
            Assert-MockCalled -CommandName Remove-CacheItem -Exactly 2

            Assert-MockCalled -CommandName Set-CacheObject -Exactly 1
            Assert-MockCalled -CommandName Refresh-CacheObject -Exactly 1
        }

    }

    Context 'When removing Area nodes' {

        It 'Should remove area nodes with reclassification and update cache' {
            # Arrange
            $areaLookupResult = @{
                propertiesChanged = @{
                    ToRemove = @(
                        @{ Path = "MyProject/Area/Feature2" }
                    )
                }
                cachedAreaNodes = @(
                    @{ path = "\MyProject\Area"; id = 456 }
                )
            }

            # Act
            Remove-ClassificationNodeResource -ProjectName "MyProject" -NodeType "Areas" -LookupResult $areaLookupResult -OrganizationName "TestOrg"

            # Assert
            Assert-MockCalled -CommandName Remove-ClassificationNode -Exactly 1
            Assert-MockCalled -CommandName Remove-CacheItem -Exactly 1
            Assert-MockCalled -CommandName Set-CacheObject -Exactly 1
            Assert-MockCalled -CommandName Refresh-CacheObject -Exactly 1

        }

    }

    Context 'When ProjectAreaId is missing for Areas' {

        It 'Should log an error and not proceed with removal' {

            Mock -CommandName Write-Error

            # Arrange
            $invalidAreaLookupResult = @{
                propertiesChanged = @{
                    ToRemove = @(
                        @{ Path = "MyProject/Area/Feature3" }
                    )
                }
                cachedAreaNodes = @(
                    @{ path = "\MyProject\OtherArea"; id = 789 }  # Invalid path
                )
            }

            # Act
            { Remove-ClassificationNodeResource -ProjectName "MyProject" -NodeType "Areas" -LookupResult $invalidAreaLookupResult -OrganizationName "TestOrg" } | Should -Not -Throw


            #
            Assert-MockCalled -CommandName Write-Error
            Assert-MockCalled -CommandName Remove-ClassificationNode -Exactly 0
            Assert-MockCalled -CommandName Remove-CacheItem -Exactly 0
            Assert-MockCalled -CommandName Set-CacheObject -Exactly 0
            Assert-MockCalled -CommandName Refresh-CacheObject -Exactly 0

        }

    }

}
