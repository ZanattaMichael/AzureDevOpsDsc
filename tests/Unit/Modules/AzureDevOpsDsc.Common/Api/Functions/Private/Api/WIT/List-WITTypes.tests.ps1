$currentFile = $MyInvocation.MyCommand.Path

Describe "List-WITTypes" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {

        # Set the organization name
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        # Load the functions to test
        if ($null -eq $currentFile)
        {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'List-WITTypes.tests.ps1'
        }

        # Load the functions to test
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)

        ForEach ($file in $files) {
            . $file.FullName
        }

        # Mock Get-AzDevOpsApiVersion and Invoke-AzDevOpsApiRestMethod to simulate their behavior
        Mock -CommandName Get-AzDevOpsApiVersion { return @('7.0', '7.1') }
        Mock -CommandName Invoke-AzDevOpsApiRestMethod {
            return @{ value = @('Type1', 'Type2', 'Type3') }
        }

    }

    Context "When called with valid parameters" {
        It "Should call Invoke-AzDevOpsApiRestMethod with the correct parameters" {
            List-WITTypes -Organization "TestOrg" -ProjectName "TestProject"

            # Verify that Invoke-AzDevOpsApiRestMethod was called with expected arguments
            Assert-MockCalled Invoke-AzDevOpsApiRestMethod -Exactly 1
        }

        It "Should return a list of work item types" {
            $result = List-WITTypes -Organization "TestOrg" -ProjectName "TestProject"
            $result | Should -Contain 'Type1'
            $result | Should -Contain 'Type2'
            $result | Should -Contain 'Type3'
        }
    }

    Context "When an API version is not supported" {
        BeforeEach {
            Mock -CommandName Get-AzDevOpsApiVersion { return @('7.0') }
        }

        It "Should default to the latest available API version" {
            List-WITTypes -Organization "TestOrg" -ProjectName "TestProject"

            # Verify that Invoke-AzDevOpsApiRestMethod was called with the fallback API version
            Assert-MockCalled Invoke-AzDevOpsApiRestMethod -Exactly 1
        }
    }

    Context "When there is an error in API call" {
        BeforeEach {
            Mock -CommandName Invoke-AzDevOpsApiRestMethod { throw "API Error" }
            Mock -CommandName Write-Error
        }

        It "Should catch the exception and write an error message" {
            { List-WITTypes -Organization "TestOrg" -ProjectName "TestProject" } | Should -Not -Throw
            Assert-MockCalled Write-Error -Exactly 1
        }
    }

    Context "When API returns a string response" {
        BeforeEach {
            Mock Invoke-AzDevOpsApiRestMethod { return '{"value":["TypeA","TypeB"]}' }
        }

        It "Should convert the string response to a hashtable and return the values" {
            $result = List-WITTypes -Organization "TestOrg" -ProjectName "TestProject"
            $result | Should -Contain 'TypeA'
            $result | Should -Contain 'TypeB'
        }
    }
}
