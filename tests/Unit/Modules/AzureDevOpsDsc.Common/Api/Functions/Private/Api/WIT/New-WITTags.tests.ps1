$currentFile = $MyInvocation.MyCommand.Path

Describe "New-WITTags" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {

        # Set the organization name
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        # Load the functions to test
        if ($null -eq $currentFile)
        {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-WITTags.tests.ps1'
        }

        # Load the functions to test
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)

        ForEach ($file in $files) {
            . $file.FullName
        }

        # Mock List-WITTypes and Invoke-AzDevOpsApiRestMethod to simulate their behavior
        Mock -CommandName List-WITTypes {
            return @(
                @{ name = 'Bug' }
                @{ name = 'Task' }
            )
        }

        Mock -CommandName Get-AzDevOpsApiVersion { return @('7.0', '7.1') }
        Mock -CommandName Invoke-AzDevOpsApiRestMethod {
            return @{ Id = 123 }
        } -ParameterFilter { $Method -eq "POST" }
        Mock -CommandName Invoke-AzDevOpsApiRestMethod { return $true } -ParameterFilter { $Method -eq "DELETE" }
    }

    Context "When called with valid parameters" {
        It "Should create a work item with specified tags and delete it" {
            $result = New-WITTags -Organization "TestOrg" -ProjectName "TestProject" -WorkItemTrackingNames "Tag1", "Tag2"

            # Assert that List-WITTypes was called to get the work item type
            Assert-MockCalled List-WITTypes -Exactly 1

            # Verify that Invoke-AzDevOpsApiRestMethod was called with expected arguments for creation
            Assert-MockCalled Invoke-AzDevOpsApiRestMethod -Exactly 1 -ParameterFilter {
                $Uri -eq 'https://dev.azure.com/TestOrg/TestProject/_apis/wit/workitems/$Bug?api-version=7.1' -and
                $Method -eq "POST"
            }

            # Verify that Invoke-AzDevOpsApiRestMethod was called with expected arguments for deletion
            Assert-MockCalled Invoke-AzDevOpsApiRestMethod -Exactly 1 -ParameterFilter {
                $Uri -eq 'https://dev.azure.com/TestOrg/TestProject/_apis/wit/workitems/123?api-version=7.1' -and
                $Method -eq "DELETE"
            }

            $result | Should -Be $true
        }
    }

    Context "When there is an error in API call" {
        BeforeEach {
            Mock Invoke-AzDevOpsApiRestMethod { throw "API Error" } -ParameterFilter { $Method -eq "POST" }
            Mock Write-Error
        }

        It "Should catch the exception and write an error message during creation" {
            New-WITTags -Organization "TestOrg" -ProjectName "TestProject" -WorkItemTrackingNames "Tag1"
            Assert-MockCalled Write-Error -Exactly 1
            Assert-MockCalled Invoke-AzDevOpsApiRestMethod -Exactly 1
        }

        It "Should catch the exception and write an error message during deletion" {
            Mock -CommandName Invoke-AzDevOpsApiRestMethod {
                return @{ Id = 123 }
            } -ParameterFilter { $Method -eq "POST" }

            Mock Invoke-AzDevOpsApiRestMethod { throw "API Error" } -ParameterFilter { $Method -eq "DELETE" }
            { New-WITTags -Organization "TestOrg" -ProjectName "TestProject" -WorkItemTrackingNames "Tag1" } | Should -Not -Throw
            Assert-MockCalled Write-Error -Exactly 1
            Assert-MockCalled Invoke-AzDevOpsApiRestMethod -Exactly 2
        }
    }
}
