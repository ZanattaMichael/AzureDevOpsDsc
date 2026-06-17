$currentFile = $MyInvocation.MyCommand.Path

Describe 'New-ClassificationNode' -Tag "Unit", "ClassificationNodes", "API" {

    BeforeAll {

        # Load the functions to test
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-ClassificationNode.tests.ps1'
        }

        # Load the functions to test
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) {
            . $file.FullName
        }

        $mockOrganizationName = 'MyOrg'
        $mockProjectName = 'MyProject'
        $mockStructureType = 'Areas'
        $mockPath = 'Area1'
        $mockBody = @{
            name = 'NewArea'
        }
        $mockApiVersion = '6.0'

        # Mock response data
        $mockResponse = @{
            id = 1
            name = 'NewArea'
           path = '\Area1\NewArea'
        }

        # Mock the Get-AzDevOpsApiVersion function if used
        Mock -CommandName Get-AzDevOpsApiVersion -MockWith { return $mockApiVersion }

        # Mock the Invoke-AzDevOpsApiRestMethod function
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { return $mockResponse }

    }

    Context 'Functionality Tests' {

        It 'Should call Invoke-AzDevOpsApiRestMethod with correct parameters' {
            New-ClassificationNode -OrganizationName $mockOrganizationName -ProjectName $mockProjectName -StructureType $mockStructureType -Path $mockPath -Body $mockBody

            # Verify the mock was called with expected Uri and Method
            Assert-MockCalled -CommandName 'Invoke-AzDevOpsApiRestMethod' -Exactly 1 -ParameterFilter {
                $Uri -eq "https://dev.azure.com/$mockOrganizationName/$mockProjectName/_apis/wit/classificationnodes/$mockStructureType/Area1?api-version=$mockApiVersion" -and
                $Method -eq 'POST'
            }
        }

        It 'Should convert body to JSON format' {
            New-ClassificationNode -OrganizationName $mockOrganizationName -ProjectName $mockProjectName -StructureType $mockStructureType -Path $mockPath -Body $mockBody

            Assert-MockCalled -CommandName 'Invoke-AzDevOpsApiRestMethod' -Exactly 1 -ParameterFilter {
                $Body -eq ($mockBody | ConvertTo-Json)
            }
        }

        It 'Should return response when API call is successful' {
            $result = New-ClassificationNode -OrganizationName $mockOrganizationName -ProjectName $mockProjectName -StructureType $mockStructureType -Path $mockPath -Body $mockBody

            $result | Should -Not -BeNullOrEmpty
            $result.id | Should -Be 1
            $result.name | Should -Be 'NewArea'
        }

        It 'Should handle exceptions correctly' {

            # Change mock to simulate an exception
            Mock -CommandName 'Invoke-AzDevOpsApiRestMethod' -MockWith { throw 'API Error' }
            Mock -CommandName 'Write-Error'
            { New-ClassificationNode -OrganizationName $mockOrganizationName -ProjectName $mockProjectName -StructureType $mockStructureType -Path $mockPath -Body $mockBody } | Should -Not -Throw
            Assert-MockCalled -CommandName 'Write-Error' -Exactly 1

        }

    }

}
