$currentFile = $MyInvocation.MyCommand.Path

Describe "List-WITTags" -Tag "Unit", "WIT" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {

        # Set the organization name
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        # Load the functions to test
        if ($null -eq $currentFile)
        {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'List-WITTags.tests.ps1'
        }

        # Load the functions to test
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)

        ForEach ($file in $files) {
            . $file.FullName
        }

        # Mock Get-AzDevOpsApiVersion and Invoke-AzDevOpsApiRestMethod to simulate their behavior
        Mock -CommandName Get-AzDevOpsApiVersion { return @('7.0', '7.1') }
        Mock -CommandName Invoke-AzDevOpsApiRestMethod { return @{ value = @('Tag1', 'Tag2', 'Tag3') } }
    }

    Context "When called with valid parameters" {
        It "Should call Invoke-AzDevOpsApiRestMethod with the correct parameters" {
            List-WITTags -Organization "TestOrg" -ProjectName "TestProject"

            # Verify that Invoke-AzDevOpsApiRestMethod was called with expected arguments
            Assert-MockCalled Invoke-AzDevOpsApiRestMethod -Exactly 1
        }

        It "Should return a list of tags" {
            $result = List-WITTags -Organization "TestOrg" -ProjectName "TestProject"
            $result | Should -Contain 'Tag1'
            $result | Should -Contain 'Tag2'
            $result | Should -Contain 'Tag3'
        }
    }

    Context "When an API version is not supported" {
        BeforeEach {
            Mock Get-AzDevOpsApiVersion { return @('7.0') }
        }

        It "Should default to the latest available API version" {
            List-WITTags -Organization "TestOrg" -ProjectName "TestProject"

            # Verify that Invoke-AzDevOpsApiRestMethod was called with the fallback API version
            Assert-MockCalled Invoke-AzDevOpsApiRestMethod -Exactly 1
        }
    }

    Context "When there is an error in API call" {
        BeforeEach {
            Mock Invoke-AzDevOpsApiRestMethod { throw "API Error" }
        }

        It "Should catch the exception and write an error message" {
            Mock -CommandName Write-Error
            { List-WITTags -Organization "TestOrg" -ProjectName "TestProject" } | Should -Not -Throw
            Assert-MockCalled Write-Error -Exactly 1
        }
    }
}
