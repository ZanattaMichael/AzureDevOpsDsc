$currentFile = $MyInvocation.MyCommand.Path

Describe 'Set-AzDoGitPermission Tests' {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }

        # Load the functions to test
        if ($null -eq $currentFile){
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-AzDoAreaNodes.tests.ps1'
        }

        # Load the functions to test
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)

        ForEach ($file in $files) {
            . $file.FullName
        }

        # Load Get-AzDoCacheObjects
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        # Load the summary state
        . (Get-ClassFilePath 'DSCGetSummaryState')
        . (Get-ClassFilePath '000.CacheItem')
        . (Get-ClassFilePath 'Ensure')

        # Mock external dependencies used within New-AzDoAreaNodes
        Mock -CommandName New-ClassificationNodeResource
        Mock -CommandName Remove-ClassificationNodeResource

        $lookupResult = @{
            Key = 'Value'
        }

    }

    AfterAll {
        # Clean up any global variables or state
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    Context 'When ProjectName is specified and LookupResult has nodes to add' {
        It 'Should call New-ClassificationNodeResource with correct parameters' {
            # Arrange
            $projectName = "MyProject"
            $lookupResult = @{
                cachedAreaNodes = @(
                    @{ path = "\$ProjectName\Area"; id = 123 }
                )
                propertiesChanged = @{
                    toAdd = @("Area1", "Area2")
                    toRemove = @()
                }
            }

            # Act
            Set-AzDoAreaNodes -ProjectName $projectName -LookupResult $lookupResult

            # Assert
            Assert-MockCalled -CommandName New-ClassificationNodeResource -Exactly 1 -Scope It -ParameterFilter {
                $ProjectName -eq $projectName -and
                $NodeType -eq 'Areas' -and
                $LookupResult -eq $lookupResult -and
                $OrganizationName -eq $Global:DSCAZDO_OrganizationName
            }
        }
    }

    Context 'When LookupResult has nodes to remove' {

        It 'Should call Remove-ClassificationNodeResource with correct parameters' {
            # Arrange
            $projectName = "MyProject"
            $lookupResult = @{
                cachedAreaNodes = @(
                    @{ path = "\$ProjectName\Area"; id = 123 }
                )
                propertiesChanged = @{
                    toAdd = @()
                    toRemove = @("Area1", "Area2")
                }
            }

            # Act
            Set-AzDoAreaNodes -ProjectName $projectName -LookupResult $lookupResult

            # Assert
            Assert-MockCalled -CommandName Remove-ClassificationNodeResource -Exactly 1 -Scope It -ParameterFilter {
                $ProjectName -eq $projectName -and
                $NodeType -eq 'Areas' -and
                $LookupResult -eq $lookupResult -and
                $OrganizationName -eq $Global:DSCAZDO_OrganizationName
            }
        }
    }

    Context 'When ProjectAreaId is null' {
        It 'Should log an error and not proceed with node operations' {
            # Arrange
            $projectName = "MyProject"
            $lookupResult = @{
                cachedAreaNodes = @()
                propertiesChanged = @{
                    toAdd = @("Area1", "Area2")
                    toRemove = @("Area3")
                }
            }

            Mock -CommandName Write-Error

            # Act
            { Set-AzDoAreaNodes -ProjectName $projectName -LookupResult $lookupResult } | Should -Not -Throw

            # Assert
            Assert-MockCalled -CommandName Write-Error -Times 1

        }
    }

    Context 'When Force parameter is used' {
        It 'Should force operations without confirmation' {
            # Arrange
            $projectName = "MyProject"
            $force = $true
            $lookupResult = @{
                cachedAreaNodes = @(
                    @{ path = "\$ProjectName\Area"; id = 123 }
                )
                propertiesChanged = @{
                    toAdd = @("Area1")
                    toRemove = @("Area2")
                }
            }

            # Act
            Set-AzDoAreaNodes -ProjectName $projectName -LookupResult $lookupResult -Force:$force

            # Assert
            Assert-MockCalled -CommandName New-ClassificationNodeResource -Exactly 1 -Scope It
            Assert-MockCalled -CommandName Remove-ClassificationNodeResource -Exactly 1 -Scope It
        }
    }

}
