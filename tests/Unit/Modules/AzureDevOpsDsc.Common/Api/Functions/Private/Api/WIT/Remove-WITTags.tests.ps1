$currentFile = $MyInvocation.MyCommand.Path

Describe "Remove-WITTags" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {

        # Set the organization name
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'

        # Load the functions to test
        if ($null -eq $currentFile)
        {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Remove-AzDoWIPTags.tests.ps1'
        }

        # Load the functions to test
        $files = Get-FunctionItem (Find-MockedFunctions -TestFilePath $currentFile)

        ForEach ($file in $files) {
            . $file.FullName
        }

        . (Get-ClassFilePath 'Ensure')
        . (Get-ClassFilePath 'DSCGetSummaryState')
        # Load Get-AzDoCacheObjects
        . (Get-FunctionItem 'Get-AzDoCacheObjects.ps1')

        # Mock Get-AzDevOpsApiVersion and Invoke-AzDevOpsApiRestMethod to simulate their behavior
        Mock -CommandName Get-AzDevOpsApiVersion { return @('7.0', '7.1') }
        Mock -CommandName Invoke-AzDevOpsApiRestMethod {
            return $true
        }

    }

    Context "When called with valid parameters" {
        It "Should delete specified tags successfully" {
            Remove-WITTags -Organization "TestOrg" -ProjectName "TestProject" -WorkItemTrackingTagId "Tag1", "Tag2"

            # Verify that Invoke-AzDevOpsApiRestMethod was called with expected arguments for each tag
            Assert-MockCalled Invoke-AzDevOpsApiRestMethod -Exactly 2 -Scope It -ParameterFilter {
                $Uri -match 'https://dev.azure.com/TestOrg/TestProject/_apis/wit/tags/(Tag1|Tag2)\?api-version=7.1' -and
                $Method -eq "DELETE"
            }
        }
    }

    Context "When there is an error in API call" {
        BeforeEach {
            Mock Invoke-AzDevOpsApiRestMethod { throw "API Error" }
            Mock Write-Error
        }

        It "Should catch the exception and write an error message" {
            { Remove-WITTags -Organization "TestOrg" -ProjectName "TestProject" -WorkItemTrackingTagId "Tag1" } | Should -Not -Throw
            Assert-MockCalled Write-Error -Exactly 1
        }
    }
}
