$currentFile = $MyInvocation.MyCommand.Path

Describe 'Format-ClassificationNode Tests' -Tag "Unit", "Helper", "Cache" {

    BeforeAll {

        # Set the Project
        $null = Set-Variable -Name "AzDoProject" -Value @() -Scope Global

        # Load the functions to test
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Format-ClassificationNode.tests.ps1'
        }

        # Load the functions to test
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) {
            . $file.FullName
        }

        # Load Get-AzDoCacheObjects
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        # Mocking the Add-CacheItem function
        Mock -CommandName Add-CacheItem

        # Sample node data for testing
        $nodeWithAttributesAndChildren = @{
            id = 1
            identifier = "Node1"
            name = "Node One"
            structureType = "Iteration"
            path = "Project/Iteration/Node1"
            url = "http://example.com/node1"
            attributes = @{
                startDate = "2023-01-01"
                finishDate = "2023-12-31"
            }
            hasChildren = $true
            children = @(
                @{
                    id = 2
                    identifier = "Node2"
                    name = "Node Two"
                    structureType = "Iteration"
                    path = "Project/Iteration/Node1/Node2"
                    url = "http://example.com/node2"
                    hasChildren = $false
                }
            )
        }

        $nodeWithoutAttributesOrChildren = @{
            id = 3
            identifier = "Node3"
            name = "Node Three"
            structureType = "Area"
            path = "Project/Area/Node3"
            url = "http://example.com/node3"
            hasChildren = $false
        }

    }

    Context 'When node has attributes and children' {

        It 'Should add node and its children to cache with attributes' {
            # Act
            Format-ClassificationNode -Node $nodeWithAttributesAndChildren -CacheType "LiveIterations"

            # Assert
            Assert-MockCalled -CommandName Add-CacheItem -Exactly 2 -Scope It

            # Validate the parameters passed to Add-CacheItem
            $expectedParamsParent = @{
                Key = "Project/Iteration/Node1"
                Value = @{
                    id = 1
                    identifier = "Node1"
                    name = "Node One"
                    structureType = "Iteration"
                    path = "Project/Iteration/Node1"
                    url = "http://example.com/node1"
                    startDate = "2023-01-01"
                    endDate = "2023-12-31"
                }
                Type = "LiveIterations"
                SuppressWarning = $true
            }

            $expectedParamsChild = @{
                Key = "Project/Iteration/Node1/Node2"
                Value = @{
                    id = 2
                    identifier = "Node2"
                    name = "Node Two"
                    structureType = "Iteration"
                    path = "Project/Iteration/Node1/Node2"
                    url = "http://example.com/node2"
                }
                Type = "LiveIterations"
                SuppressWarning = $true
            }

            Assert-MockCalled -CommandName Add-CacheItem -Exactly 1 -Scope It -ParameterFilter {
                $Key -eq $expectedParamsParent.Key -and
                $Value.id -eq $expectedParamsParent.Value.id -and
                $Value.startDate -eq $expectedParamsParent.Value.startDate
            }

            Assert-MockCalled -CommandName Add-CacheItem -Exactly 1 -Scope It -ParameterFilter {
                $Key -eq $expectedParamsChild.Key -and
                $Value.id -eq $expectedParamsChild.Value.id
            }
        }
    }

    Context 'When node has no attributes or children' {

        It 'Should add node to cache without attributes' {
            # Act
            Format-ClassificationNode -Node $nodeWithoutAttributesOrChildren -CacheType "LiveAreaNodes"

            # Assert
            Assert-MockCalled -CommandName Add-CacheItem -Exactly 1 -Scope It

            # Validate the parameters passed to Add-CacheItem
            $expectedParams = @{
                Key = "Project/Area/Node3"
                Value = @{
                    id = 3
                    identifier = "Node3"
                    name = "Node Three"
                    structureType = "Area"
                    path = "Project/Area/Node3"
                    url = "http://example.com/node3"
                }
                Type = "LiveAreas"
                SuppressWarning = $true
            }

            Assert-MockCalled -CommandName Add-CacheItem -Exactly 1 -Scope It -ParameterFilter {
                $Key -eq $expectedParams.Key -and
                $Value.id -eq $expectedParams.Value.id
            }
        }
    }

    # Add more test cases as needed

    Context "When node has no children" {

        It 'Should add node to cache without attributes' {
            # Act
            Format-ClassificationNode -Node $nodeWithoutAttributesOrChildren -CacheType "LiveAreaNodes"

            # Assert
            Assert-MockCalled -CommandName Add-CacheItem -Exactly 1 -Scope It

            # Validate the parameters passed to Add-CacheItem
            $expectedParams = @{
                Key = "Project/Area/Node3"
                Value = @{
                    id = 3
                    identifier = "Node3"
                    name = "Node Three"
                    structureType = "Area"
                    path = "Project/Area/Node3"
                    url = "http://example.com/node3"
                }
                Type = "LiveAreas"
                SuppressWarning = $true
            }

            Assert-MockCalled -CommandName Add-CacheItem -Exactly 1 -Scope It -ParameterFilter {
                $Key -eq $expectedParams.Key -and
                $Value.id -eq $expectedParams.Value.id
            }
        }
    }

    Context "Partial Data" {

        It 'Should handle partial Area data gracefully' {
            # Act
            $partialNode = @{
                id = 4
                identifier = "Node4"
                name = "Node Four"
                structureType = "Area"
                path = "Project/Area/Node4"
                url = "http://example.com/node4"
            }

            Format-ClassificationNode -Node $partialNode -CacheType "LiveAreaNodes"

            # Assert
            Assert-MockCalled -CommandName Add-CacheItem -Exactly 1 -Scope It

            # Validate the parameters passed to Add-CacheItem
            $expectedParams = @{
                Key = "Project/Area/Node4"
                Value = @{
                    id = 4
                    identifier = "Node4"
                    name = "Node Four"
                    structureType = "Area"
                    path = "Project/Area/Node4"
                    url = "http://example.com/node4"
                }
                Type = "LiveAreas"
                SuppressWarning = $true
            }

            Assert-MockCalled -CommandName Add-CacheItem -Exactly 1 -Scope It -ParameterFilter {
                $Key -eq $expectedParams.Key -and
                $Value.id -eq $expectedParams.Value.id
            }
        }

        It "Should be able to handle a start date but missing end date" {
            # Act
            $partialNodeWithStartDate = @{
                id = 5
                identifier = "Node5"
                name = "Node Five"
                structureType = "Iteration"
                path = "Project/Iteration/Node5"
                url = "http://example.com/node5"
                attributes = @{
                    startDate = "2023-01-01"
                }
            }

            Format-ClassificationNode -Node $partialNodeWithStartDate -CacheType "LiveIterations"

            # Assert
            Assert-MockCalled -CommandName Add-CacheItem -Exactly 1 -Scope It

            # Validate the parameters passed to Add-CacheItem
            $expectedParams = @{
                Key = "Project/Iteration/Node5"
                Value = @{
                    id = 5
                    identifier = "Node5"
                    name = "Node Five"
                    structureType = "Iteration"
                    path = "Project/Iteration/Node5"
                    url = "http://example.com/node5"
                    startDate = "2023-01-01"
                }
                Type = "LiveIterations"
                SuppressWarning = $true
            }

            Assert-MockCalled -CommandName Add-CacheItem -Exactly 1 -Scope It -ParameterFilter {
                $Key -eq $expectedParams.Key -and
                $Value.id -eq $expectedParams.Value.id
            }
        }

    }

}
