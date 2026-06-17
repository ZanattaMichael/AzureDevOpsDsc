$currentFile = $MyInvocation.MyCommand.Path

Describe 'AzDoAPI_9_DevOpsClassificationNodes Tests' -Tag "Unit", "Cache Initalization", "Cache" {

    BeforeAll {

        # Mocking global variable
        $Global:DSCAZDO_OrganizationName = 'DefaultOrg'

        # Load the functions to test
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath '9.DevOpsClassificationNodes.tests.ps1'
        }

        # Load the functions to test
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)

        ForEach ($file in $files) {
            . $file.FullName
        }

        # Load Get-AzDoCacheObjects
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        # Mocking auxiliary functions
        Mock -CommandName Get-CacheObject -MockWith {
            return @(
                @{ value = @{ name = 'Project1' } },
                @{ value = @{ name = 'Project2' } }
            )
        }

        Mock -CommandName List-DevOpsClassificationNodes -MockWith {
            param($ProjectName, $OrganizationName)

            if ($ProjectName -eq 'Project1') {

                return @(
                    @{
                        structureType = 'area'
                        path = 'Area1'
                        id = 1
                        identifier = 'A1'
                        name = 'AreaNode1'
                        url = 'http://example.com/area1'
                        hasChildren = $false
                    },
                    @{
                        structureType = 'iteration'
                        path = 'Iteration1'
                        id = 2
                        identifier = 'I1'
                        name = 'IterationNode1'
                        url = 'http://example.com/iteration1'
                        hasChildren = $true
                        children = @(
                            @{ mockKey = 'value'},
                            @{ secondMockKey = 'value2'}
                        )
                    }
                )

            }
            elseif ($ProjectName -eq 'Project2') {

                return @(
                    @{
                        structureType = 'area'
                        path = 'Area2'
                        id = 3
                        identifier = 'A2'
                        name = 'AreaNode2'
                        url = 'http://example.com/area2'
                        hasChildren = $false
                    }
                )

            }

        }

        Mock -CommandName Add-CacheItem
        Mock -CommandName Format-ClassificationNode
        Mock -CommandName Export-CacheObject

    }

    Context 'When no organization name is provided' {

        It 'Should use the global organization name' {
            # Act
            AzDoAPI_9_DevOpsClassificationNodes

            # Assert
            Assert-MockCalled -CommandName Get-CacheObject -Exactly 1
            Assert-MockCalled -CommandName List-DevOpsClassificationNodes -Exactly 2
        }

    }

    Context 'When processing projects with classification nodes' {

        It 'Should categorize nodes into area and iteration caches' {
            # Act
            AzDoAPI_9_DevOpsClassificationNodes -OrganizationName 'TestOrg'

            # Assert
            Assert-MockCalled -CommandName Add-CacheItem -Exactly 3
            Assert-MockCalled -CommandName Format-ClassificationNode -Exactly 2
            Assert-MockCalled -CommandName Export-CacheObject -Exactly 2
        }

    }

}
