$currentFile = $MyInvocation.MyCommand.Path

Describe 'New-AzDoIterationNodes Tests' {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {

        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        # Load the functions to test
        if ($null -eq $currentFile){
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-AzDoIterationNodes.tests.ps1'
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


        # Mock the external dependency used within New-AzDoIterationNodes
        Mock -CommandName New-ClassificationNodeResource -MockWith {
            param($params)
            return @()
        }

        $lookupResult = @{
            Key = 'Value'
        }

    }

    Context 'When ProjectName is specified with IterationAttributes' {
        It 'Should call New-ClassificationNodeResource with correct parameters' {
            # Arrange
            $projectName = "MyProject"
            $iterationAttributes = @(@{ Name = "Iteration1" }, @{ Name = "Iteration2" })

            # Act
            New-AzDoIterationNodes -ProjectName $projectName -IterationAttributes $iterationAttributes -LookupResult $lookupResult

            # Assert
            Assert-MockCalled -CommandName New-ClassificationNodeResource -Times 1
        }
    }

    Context 'When Force parameter is used' {
        It 'Should proceed even if iterations exist' {
            # Arrange
            $projectName = "MyProject"
            $force = $true
            $iterationAttributes = @(@{ Name = "Iteration1" })

            # Act
            New-AzDoIterationNodes -ProjectName $projectName -IterationAttributes $iterationAttributes -Force:$force -LookupResult $lookupResult

            # Assert
            Assert-MockCalled -CommandName New-ClassificationNodeResource -Times 1
        }
    }

    Context 'When Ensure parameter is not specified' {
        It 'Should execute without errors' {
            # Arrange
            $projectName = "MyProject"
            $iterationAttributes = @(@{ Name = "Iteration1" })

            # Act
            { New-AzDoIterationNodes -ProjectName $projectName -IterationAttributes $iterationAttributes -LookupResult $lookupResult } | Should -Not -Throw
        }
    }

    Context 'When no IterationAttributes are provided' {
        It 'Should handle empty IterationAttributes gracefully' {
            # Arrange
            $projectName = "MyProject"

            # Act
            New-AzDoIterationNodes -ProjectName $projectName -LookupResult $lookupResult

            # Assert
            Assert-MockCalled -CommandName New-ClassificationNodeResource -Times 1
        }
    }

}
