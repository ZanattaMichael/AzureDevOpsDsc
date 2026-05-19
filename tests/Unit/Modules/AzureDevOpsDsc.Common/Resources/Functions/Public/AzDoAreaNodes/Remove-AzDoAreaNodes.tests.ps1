$currentFile = $MyInvocation.MyCommand.Path

Describe 'Remove-AzDoGitPermission Tests' {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        # Load the functions to test
        if ($null -eq $currentFile){
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Remove-AzDoAreaNodes.tests.ps1'
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

        # Mock external dependencies used within Remove-AzDoAreaNodes
        Mock -CommandName Remove-ClassificationNodeResource

        $lookupResult = @{
            Key = 'Value'
        }


    }

    AfterAll {
        # Clean up any global variables or state
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    Context 'When ProjectName is specified' {
        It 'Should call Remove-ClassificationNodeResource with correct parameters' {
            # Arrange
            $projectName = "MyProject"
            $areaPaths = @("Area1", "Area2")

            # Act
            Remove-AzDoAreaNodes -ProjectName $projectName -AreaPaths $areaPaths -LookupResult $lookupResult

            # Assert
            Assert-MockCalled -CommandName Remove-ClassificationNodeResource -Exactly 1 -ParameterFilter {
                $ProjectName -eq $projectName -and
                $NodeType -eq 'Areas' -and
                $OrganizationName -eq $Global:DSCAZDO_OrganizationName
            }
        }
    }

    Context 'When Force parameter is used' {
        It 'Should call Remove-ClassificationNodeResource without confirmation' {
            # Arrange
            $projectName = "MyProject"
            $force = $true

            # Act
            Remove-AzDoAreaNodes -ProjectName $projectName -Force:$force -LookupResult $lookupResult

            # Assert
            Assert-MockCalled -CommandName Remove-ClassificationNodeResource -Exactly 1
        }
    }

    Context 'With LookupResult parameter' {
        It 'Should pass LookupResult to Remove-ClassificationNodeResource' {
            # Arrange
            $projectName = "MyProject"
            $lookupResult = @{ Key = "Value" }

            # Act
            Remove-AzDoAreaNodes -ProjectName $projectName -LookupResult $lookupResult

            # Assert
            Assert-MockCalled -CommandName Remove-ClassificationNodeResource -Exactly 1 -ParameterFilter {
                $LookupResult -eq $lookupResult
            }
        }
    }

    Context 'When Ensure parameter is specified' {
        It 'Should handle Ensure parameter correctly (currently no specific logic)' {
            # Arrange
            $projectName = "MyProject"
            $ensure = [Ensure]::Absent

            # Act
            Remove-AzDoAreaNodes -ProjectName $projectName -Ensure $ensure -LookupResult $lookupResult

            # Assert
            # No specific behavior change in this function for Ensure, just ensuring it doesn't break
            Assert-MockCalled -CommandName Remove-ClassificationNodeResource -Exactly 1
        }
    }

    Context 'When AreaPaths is not provided' {
        It 'Should still call Remove-ClassificationNodeResource without AreaPaths' {
            # Arrange
            $projectName = "MyProject"

            # Act
            Remove-AzDoAreaNodes -ProjectName $projectName -LookupResult $lookupResult

            # Assert
            Assert-MockCalled -CommandName Remove-ClassificationNodeResource -Exactly 1 -ParameterFilter {
                $ProjectName -eq $projectName -and
                $NodeType -eq 'Areas' -and
                $OrganizationName -eq $Global:DSCAZDO_OrganizationName
            }
        }
    }

}
