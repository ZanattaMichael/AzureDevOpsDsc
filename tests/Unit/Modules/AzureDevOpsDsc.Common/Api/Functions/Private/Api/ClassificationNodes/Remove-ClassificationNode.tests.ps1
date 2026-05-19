$currentFile = $MyInvocation.MyCommand.Path

Describe 'New-ClassificationNode' -Tags "Unit", "API" {

    BeforeAll {

        # Load the functions to test
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Remove-ClassificationNode.tests.ps1'
        }

        # Load the functions to test
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) {
            . $file.FullName
        }

        # Setup: Define mock values and parameters
        $mockOrganizationName = 'MyOrg'
        $mockProjectName = 'MyProject'
        $mockStructureType = 'Areas'
        $mockPath = 'Area1'
        $mockReclassificationId = '12345'
        $mockApiVersion = '6.0'

        # Mock the Get-AzDevOpsApiVersion function if used
        Mock -CommandName Get-AzDevOpsApiVersion -MockWith { return $mockApiVersion }

        # Mock the Invoke-AzDevOpsApiRestMethod function
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { return $null }

    }

    Context 'Functionality Tests' {

        It 'Should call Invoke-AzDevOpsApiRestMethod with correct parameters without ReclassificationId' {
            Remove-ClassificationNode -OrganizationName $mockOrganizationName -ProjectName $mockProjectName -StructureType $mockStructureType -Path $mockPath

            # Verify the mock was called with expected Uri and Method
            Assert-MockCalled -CommandName 'Invoke-AzDevOpsApiRestMethod' -Exactly 1 -Scope It -ParameterFilter {
                $Uri -eq "https://dev.azure.com/MyOrg/MyProject/_apis/wit/classificationnodes/Areas/Area1?api-version=6.0" -and
                $Method -eq 'DELETE'
            }
        }

        It 'Should call Invoke-AzDevOpsApiRestMethod with correct parameters including ReclassificationId' {
            Remove-ClassificationNode -OrganizationName $mockOrganizationName -ProjectName $mockProjectName -StructureType $mockStructureType -Path $mockPath -ReclassificationId $mockReclassificationId

            # Verify the mock was called with expected Uri and Method
            Assert-MockCalled -CommandName 'Invoke-AzDevOpsApiRestMethod' -Exactly 1 -Scope It -ParameterFilter {
                $Uri -eq "https://dev.azure.com/MyOrg/MyProject/_apis/wit/classificationnodes/Areas/Area1?api-version=6.0&`$reclassifyId=12345" -and
                $Method -eq 'DELETE'
            }
        }

        It 'Should handle exceptions correctly' {
            # Change mock to simulate an exception
            Mock -CommandName 'Invoke-AzDevOpsApiRestMethod' -MockWith { throw 'API Error' }
            Mock -CommandName Write-Error

            { Remove-ClassificationNode -OrganizationName $mockOrganizationName -ProjectName $mockProjectName -StructureType $mockStructureType -Path $mockPath } | Should -Not -Throw
            Assert-MockCalled -CommandName Write-Error -Exactly 1
        }

    }

}
