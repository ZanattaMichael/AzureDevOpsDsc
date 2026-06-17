$currentFile = $MyInvocation.MyCommand.Path

Describe 'List-DevOpsGitRepository' -Tag "Unit", "Cache", "API" {

    BeforeAll {

        # Load the functions to test
        if ($null -eq $currentFile) {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'List-DevOpsClassificationNodes.tests.ps1'
        }

        # Load the functions to test
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)
        ForEach ($file in $files) {
            . $file.FullName
        }

        # Setup: Define mock values and parameters
        $mockOrganizationName = 'MyOrg'
        $mockProjectName = 'MyProject'
        $mockApiVersion = '6.0'

        # Mock response data
        $mockResponse = @{
            value = @(
                @{ name = 'Area1'; path = '\Area1' },
                @{ name = 'Area2'; path = '\Area2' }
            )
        }

        # Mock the Get-AzDevOpsApiVersion function if used
        Mock -CommandName Get-AzDevOpsApiVersion -MockWith { return $mockApiVersion }

        # Mock the Invoke-AzDevOpsApiRestMethod function
        Mock -CommandName Invoke-AzDevOpsApiRestMethod -MockWith { return $mockResponse }

    }


    Context 'Functionality Tests' {
        It 'Should call Invoke-AzDevOpsApiRestMethod with correct parameters' {
            List-DevOpsClassificationNodes -OrganizationName $mockOrganizationName -ProjectName $mockProjectName

            # Verify the mock was called with expected Uri
            Assert-MockCalled -CommandName 'Invoke-AzDevOpsApiRestMethod' -Exactly 1 -ParameterFilter {
                $Uri -eq "https://dev.azure.com/$mockOrganizationName/$mockProjectName/_apis/wit/classificationnodes?`$depth=100"
            }
        }

        It 'Should return classification nodes when API returns data' {
            $result = List-DevOpsClassificationNodes -OrganizationName $mockOrganizationName -ProjectName $mockProjectName

            $result | Should -Not -BeNullOrEmpty
            $result | Should -HaveCount 2
            $result[0].name | Should -Be 'Area1'
            $result[1].name | Should -Be 'Area2'
        }

        It 'Should return null when API returns no data' {
            # Change mock to simulate no data
            Mock -CommandName 'Invoke-AzDevOpsApiRestMethod' -MockWith { return @{ value = $null } }

            $result = List-DevOpsClassificationNodes -OrganizationName $mockOrganizationName -ProjectName $mockProjectName

            $result | Should -Be $null
        }
    }

}
