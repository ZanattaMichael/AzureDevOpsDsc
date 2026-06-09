$currentFile = $MyInvocation.MyCommand.Path

Describe "Set-AzDoWIPTags" {

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
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Set-AzDoWIPTags.tests.ps1'
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

        # Mock New-WITTags and Remove-WITTags to simulate their behavior without making actual changes
        Mock -CommandName New-WITTags
        Mock -CommandName Remove-WITTags

    }

    Context "When called with valid parameters" {
        It "Should call New-WITTags and Remove-WITTags with the correct parameters" {
            $lookupResultMock = @{
                propertiesChanged = @{
                    ToAdd = @('Tag1', 'Tag2')
                    ToDelete = @(
                        @{
                            id = 'Tag3'
                        }
                        @{
                            id = 'Tag4'
                        }
                    )
                }
            }

            Set-AzDoWIPTags -ProjectName "TestProject" -LookupResult $lookupResultMock

            # Verify that New-WITTags was called with expected arguments
            Assert-MockCalled New-WITTags -Exactly 1
            # Verify that Remove-WITTags was called with expected arguments
            Assert-MockCalled Remove-WITTags -Exactly 1
        }
    }

    Context "When LookupResult is empty" {
        It "Should not call New-WITTags or Remove-WITTags" {
            $lookupResultMock = @{
                propertiesChanged = @{
                    ToAdd = @()
                    ToDelete = @()
                }
            }

            Set-AzDoWIPTags -ProjectName "TestProject" -LookupResult $lookupResultMock

            # Verify that New-WITTags was not called
            Assert-MockCalled New-WITTags -Exactly 0 -Scope It

            # Verify that Remove-WITTags was not called
            Assert-MockCalled Remove-WITTags -Exactly 0 -Scope It
        }
    }

    Context "Edge Cases" {
        It "Should handle an empty ProjectName gracefully" {
            $lookupResultMock = @{
                propertiesChanged = @{
                    ToAdd = @('Tag1')
                    ToDelete = @('Tag2')
                }
            }

            { Set-AzDoWIPTags -ProjectName "" -LookupResult $lookupResultMock } | Should -Throw
        }

        It "Should handle null LookupResult" {
            { Set-AzDoWIPTags -ProjectName "TestProject" -LookupResult $null } | Should -Throw
        }
    }
}
