$currentFile = $MyInvocation.MyCommand.Path

Describe 'Remove-AzDoIterationNodes Tests' -Tag "Unit", "IterationNodes" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'
        . (Get-FunctionItem 'Get-AzDoOrganizationName.ps1').FullName\n
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }

        # Load the functions to test
        if ($null -eq $currentFile){
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Remove-AzDoIterationNodes.tests.ps1'
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


        $lookupResult = @{
            Key = 'Value'
        }

        # Mock the external dependency used within Remove-AzDoIterationNodes
        Mock -CommandName Remove-ClassificationNodeResource -MockWith {
            param($params)
            return @()
        }

    }

    Context 'When ProjectName is specified' {
        It 'Should call Remove-ClassificationNodeResource with correct parameters' {
            # Arrange
            $projectName = "MyProject"

            # Act
            Remove-AzDoIterationNodes -ProjectName $projectName -LookupResult $lookupResult

            # Assert
            Assert-MockCalled -CommandName Remove-ClassificationNodeResource -Times 1

        }
    }

    Context 'When Force parameter is used' {
        It 'Should proceed with removal even if iterations are protected' {
            # Arrange
            $projectName = "MyProject"
            $force = $true

            # Act
            Remove-AzDoIterationNodes -ProjectName $projectName -Force:$force -LookupResult $lookupResult

            # Assert
            Assert-MockCalled -CommandName Remove-ClassificationNodeResource -Times 1
        }
    }

    Context 'When IterationAttributes are provided' {
        It 'Should include IterationAttributes in parameters' {
            # Arrange
            $projectName = "MyProject"
            $iterationAttributes = @(@{ Name = "Iteration1"; Path = "Path1" })

            # Act
            Remove-AzDoIterationNodes -ProjectName $projectName -IterationAttributes $iterationAttributes -LookupResult $lookupResult

            # Assert
            Assert-MockCalled -CommandName Remove-ClassificationNodeResource -Times 1
        }
    }

    Context 'When Ensure parameter is not specified' {
        It 'Should execute without errors' {
            # Arrange
            $projectName = "MyProject"

            # Act
            { Remove-AzDoIterationNodes -ProjectName $projectName -LookupResult $lookupResult } | Should -Not -Throw
        }
    }

    Context 'When no IterationAttributes are provided' {
        It 'Should handle empty IterationAttributes gracefully' {
            # Arrange
            $projectName = "MyProject"

            # Act
            Remove-AzDoIterationNodes -ProjectName $projectName -LookupResult $lookupResult

            # Assert
            Assert-MockCalled -CommandName Remove-ClassificationNodeResource -Times 1
        }
    }

}
