$currentFile = $MyInvocation.MyCommand.Path

Describe 'New-AzDoAreaNodes Tests' {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }

        # Load the functions to test
        if ($null -eq $currentFile){
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-AzDoAreaNodes.tests.ps1'
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

        $lookupResult = @{
            Key = 'Value'
        }

    }

    AfterAll {
        # Clean up any global variables or state
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    Context 'When ProjectName is specified' {

        It 'Should call New-ClassificationNodeResource with correct parameters' {
            # Arrange
            $projectName = "MyProject"
            $areaPaths = @("Area1", "Area2")

            # Act
            New-AzDoAreaNodes -ProjectName $projectName -AreaPaths $areaPaths -LookupResult $lookupResult

            # Assert
            Assert-MockCalled -CommandName New-ClassificationNodeResource -Exactly 1 -ParameterFilter {
                $ProjectName -eq $projectName -and
                $NodeType -eq 'Areas' -and
                $OrganizationName -eq $Global:DSCAZDO_OrganizationName
            }
        }

    }

    Context 'When Force parameter is used' {

        It 'Should call New-ClassificationNodeResource even if nodes exist' {
            # Arrange
            $projectName = "MyProject"
            $areaPaths = @("Area1", "Area2")
            $force = $true

            # Act
            New-AzDoAreaNodes -ProjectName $projectName -AreaPaths $areaPaths -Force:$force -LookupResult $lookupResult

            # Assert
            Assert-MockCalled -CommandName New-ClassificationNodeResource -Exactly 1 -Scope It
        }

    }

    Context 'With LookupResult parameter' {

        It 'Should pass LookupResult to New-ClassificationNodeResource' {
            # Arrange
            $projectName = "MyProject"
            $lookupResult = @{ Key = "Value" }

            # Act
            New-AzDoAreaNodes -ProjectName $projectName -LookupResult $lookupResult

            # Assert
            Assert-MockCalled -CommandName New-ClassificationNodeResource -Exactly 1 -ParameterFilter {
                $LookupResult -eq $lookupResult
            }
        }

    }

    Context 'When Ensure parameter is specified' {

        It 'Should handle Ensure parameter correctly (currently no specific logic)' {
            # Arrange
            $projectName = "MyProject"
            $ensure = [Ensure]::Present

            # Act
            New-AzDoAreaNodes -ProjectName $projectName -Ensure $ensure -LookupResult $lookupResult

            # Assert
            # No specific behavior change in this function for Ensure, just ensuring it doesn't break
            Assert-MockCalled -CommandName New-ClassificationNodeResource -Exactly 1 -Scope It
        }

    }

    Context 'When AreaPaths is not provided' {

        It 'Should still call New-ClassificationNodeResource without AreaPaths' {
            # Arrange
            $projectName = "MyProject"

            # Act
            New-AzDoAreaNodes -ProjectName $projectName -LookupResult $lookupResult

            # Assert
            Assert-MockCalled -CommandName New-ClassificationNodeResource -Exactly 1 -ParameterFilter {
                $ProjectName -eq $projectName -and
                $NodeType -eq 'Areas' -and
                $OrganizationName -eq $Global:DSCAZDO_OrganizationName
            }
        }

    }
}
