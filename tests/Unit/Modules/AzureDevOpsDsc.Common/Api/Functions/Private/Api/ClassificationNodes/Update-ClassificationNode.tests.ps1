$currentFile = $MyInvocation.MyCommand.Path

Describe 'New-ClassificationNode' -Tag "Unit", "ClassificationNodes", "API" {

    BeforeAll {

        # Load the functions to test
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Update-ClassificationNode.tests.ps1'
        }

        # Load the functions to test
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) {
            . $file.FullName
        }

        # Mocking the Get-AzDevOpsApiVersion function to return a fixed API version
        Mock -CommandName Get-AzDevOpsApiVersion -MockWith { return '6.0' }

        # Mocking the Invoke-AzDevOpsApiRestMethod function to simulate API call
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
            return @{ status = 'success'; message = 'Node updated successfully' }
        }

        # Mocking the Invoke-AzDevOpsApiRestMethod function to throw an exception
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith {
            throw "API call failed"
        }

    }

    Context 'When an error occurs during API call' {

        It "Should execute the function without throwing an error" {

            Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { return @{ key = 'value' } }

            # Arrange
            $organizationName = 'TestOrg'
            $projectName = 'TestProject'
            $structureType = 'Iterations'
            $path = 'AnotherPath'
            $body = @{ name = 'AnotherNodeName' }

            # Act
            $result = Update-ClassificationNode -OrganizationName $organizationName `
                                                -ProjectName $projectName `
                                                -StructureType $structureType `
                                                -Path $path `
                                                -Body $body

            # Assert
            $result | Should -Not -BeNullOrEmpty

        }

        It 'Should catch the exception and write an error message' {

            Mock -CommandName Write-Error

            # Arrange
            $organizationName = 'TestOrg'
            $projectName = 'TestProject'
            $structureType = 'Iterations'
            $path = 'AnotherPath'
            $body = @{ name = 'AnotherNodeName' }

            # Act
            { Update-ClassificationNode -OrganizationName $organizationName `
                                        -ProjectName $projectName `
                                        -StructureType $structureType `
                                        -Path $path `
                                        -Body $body } | Should -Not -Throw

            # Assert
            Assert-MockCalled -CommandName Invoke-AzDevOpsApiRestMethod -Exactly 1 -Scope It
            Assert-MockCalled -CommandName Write-Error -Exactly 1

        }
    }

}
