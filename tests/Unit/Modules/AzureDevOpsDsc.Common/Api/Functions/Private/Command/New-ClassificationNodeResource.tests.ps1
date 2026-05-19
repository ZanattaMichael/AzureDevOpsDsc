$currentFile = $MyInvocation.MyCommand.Path

Describe 'New-ClassificationNodeResource Tests' -Tags "Unit", "Cache" {

    BeforeAll {

        # Set the Project
        $null = Set-Variable -Name "AzDoProject" -Value @() -Scope Global

        # Load the functions to test
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-ClassificationNodeResource.tests.ps1'
        }

        # Load the functions to test
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) {
            . $file.FullName
        }
        # Load Get-AzDoCacheObjects
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        # Mocking auxiliary functions
        Mock -CommandName New-ClassificationNode -MockWith {
            return @{ id = 123; name = $args[0].Body.name }
        }

        Mock -CommandName Add-CacheItem
        Mock -CommandName Set-CacheObject
        Mock -CommandName Refresh-CacheObject
        Mock -CommandName Get-Variable -MockWith { return 'mockValue' }

        # Sample LookupResult for testing
        $lookupResult = @{
            propertiesChanged = @{
                ToAdd = @(
                    @{ Path = "MyProject/Iteration/Sprint1"; StartDate = "2023-01-01"; EndDate = "2023-01-31" },
                    @{ Path = "MyProject/Area/Feature1" }
                )
            }
        }

    }


    Context 'When creating Iteration nodes' {
        It 'Should create iteration nodes with correct attributes and update cache' {
            # Act
            New-ClassificationNodeResource -ProjectName "MyProject" -NodeType "Iterations" -LookupResult $lookupResult -OrganizationName "TestOrg"

            # Assert
            Assert-MockCalled -CommandName New-ClassificationNode -Exactly 2 -Scope It
            Assert-MockCalled -CommandName Add-CacheItem -Exactly 2 -Scope It

            Assert-MockCalled -CommandName Set-CacheObject -Exactly 1 -Scope It
            Assert-MockCalled -CommandName Refresh-CacheObject -Exactly 1 -Scope It
        }
    }

    Context 'When creating Area nodes' {
        It 'Should create area nodes and update cache' {
            # Arrange
            $areaLookupResult = @{
                propertiesChanged = @{
                    ToAdd = @(
                        @{ Path = "MyProject/Area/Feature2" }
                    )
                }
            }

            # Act
            New-ClassificationNodeResource -ProjectName "MyProject" -NodeType "Areas" -LookupResult $areaLookupResult -OrganizationName "TestOrg"

            # Assert
            Assert-MockCalled -CommandName New-ClassificationNode -Exactly 1 -Scope It
            Assert-MockCalled -CommandName Add-CacheItem -Exactly 1 -Scope It
            Assert-MockCalled -CommandName Set-CacheObject -Exactly 1 -Scope It
            Assert-MockCalled -CommandName Refresh-CacheObject -Exactly 1 -Scope It
        }
    }

}
