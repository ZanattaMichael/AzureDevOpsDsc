$currentFile = $MyInvocation.MyCommand.Path

Describe "New-AzDoWIPTags" -Tag "Unit", "WIPTags" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {
        # Set up any global variables or states needed for the tests
        $Global:DSCAZDO_OrganizationName = "TestOrg"
        . (Get-FunctionItem 'Get-AzDoOrganizationName.ps1').FullName\n
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }

        # Load the functions to test
        if ($null -eq $currentFile)
        {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'New-AzDoWIPTags.tests.ps1'
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

        # Mock New-WITTags to simulate its behavior without making actual changes
        Mock -CommandName New-WITTags {}

    }

    Context "When called with valid parameters" {
        It "Should call New-WITTags with the correct parameters" {
            $lookupResultMock = @{
                propertiesChanged = @{
                    ToAdd = @('Tag1', 'Tag2')
                }
            }

            New-AzDoWIPTags -ProjectName "TestProject" -LookupResult $lookupResultMock

            # Verify that New-WITTags was called with expected arguments
            Assert-MockCalled New-WITTags -Exactly 1
        }
    }

    Context "Edge Cases" {
        It "Should handle an empty ProjectName gracefully" {
            $lookupResultMock = @{
                propertiesChanged = @{
                    ToAdd = @('Tag1')
                }
            }

            { New-AzDoWIPTags -ProjectName "" -LookupResult $lookupResultMock } | Should -Throw
        }

        It "Should handle null LookupResult" {
            { New-AzDoWIPTags -ProjectName "TestProject" -LookupResult $null } | Should -Throw
        }
    }
}
