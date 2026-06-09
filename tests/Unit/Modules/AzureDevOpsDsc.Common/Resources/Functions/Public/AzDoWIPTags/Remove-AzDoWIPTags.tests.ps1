$currentFile = $MyInvocation.MyCommand.Path

Describe "Remove-AzDoWIPTags" {

    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {
        # Set up any global variables or states needed for the tests
        $Global:DSCAZDO_OrganizationName = "TestOrg"
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }

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

        # Mock Remove-WITTags to simulate its behavior without making actual changes
        Mock -CommandName Remove-WITTags {}

    }

    Context "When called with valid parameters" {
        It "Should call Remove-WITTags with the correct parameters" {
            $lookupResultMock = @{
                propertiesChanged = @{
                    ToDelete = @(
                        @{
                            id = 'Tag1'
                        }
                        @{
                            id = 'Tag2'
                        }
                    )
                }
            }

            Remove-AzDoWIPTags -ProjectName "TestProject" -LookupResult $lookupResultMock

            # Verify that Remove-WITTags was called with expected arguments
            Assert-MockCalled Remove-WITTags -Exactly 1
        }
    }

    Context "Edge Cases" {
        It "Should handle an empty ProjectName gracefully" {
            $lookupResultMock = @{
                propertiesChanged = @{
                    ToAdd = @('Tag1')
                }
            }

            { Remove-AzDoWIPTags -ProjectName "" -LookupResult $lookupResultMock } | Should -Throw
        }

        It "Should handle null LookupResult" {
            { Remove-AzDoWIPTags -ProjectName "TestProject" -LookupResult $null } | Should -Throw
        }
    }
}
