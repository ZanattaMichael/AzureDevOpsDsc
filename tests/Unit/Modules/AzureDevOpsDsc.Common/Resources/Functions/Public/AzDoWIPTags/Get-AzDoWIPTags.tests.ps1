$currentFile = $MyInvocation.MyCommand.Path

Describe "Get-AzDoWIPTags" -Tag "Unit", "WIPTags" {


    AfterAll {
        Remove-Variable -Name DSCAZDO_OrganizationName -Scope Global
    }

    BeforeAll {

        # Set the organization name
        $Global:DSCAZDO_OrganizationName = 'TestOrganization'
        . (Get-FunctionItem 'Get-AzDoOrganizationName.ps1').FullName\n
        Mock -CommandName Get-AzDoOrganizationName -MockWith { return 'TestOrganization' }

        # Load the functions to test
        if ($null -eq $currentFile)
        {
            $currentFile = Join-Path -Path $PSScriptRoot -ChildPath 'Get-AzDoWIPTags.tests.ps1'
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

        # Mock List-WITTags to simulate different scenarios
        Mock -CommandName List-WITTags {
            return @(
                @{ name = 'Tag1' },
                @{ name = 'Tag2' }
            )
        }

    }

    Context "When Ensure is Absent" {
        It "Should set status to Unchanged when no tags need to be deleted" {

            Mock -CommandName List-WITTags { return @{ name = 'Tag3' } }

            $result = Get-AzDoWIPTags -ProjectName "TestProject" -WorkItemTrackingTagList @('Tag1', 'Tag2') -Ensure ([Ensure]::Absent)
            $result.status | Should -Be Unchanged
        }

        It "Should set status to Missing when tags need to be deleted" {
            $result = Get-AzDoWIPTags -ProjectName "TestProject" -WorkItemTrackingTagList @('Tag1') -Ensure ([Ensure]::Absent)
            $result.status | Should -Be Missing
        }

        It "Should handle empty WorkItemTrackingTagList" {
            $result = Get-AzDoWIPTags -ProjectName "TestProject" -WorkItemTrackingTagList @() -Ensure ([Ensure]::Absent)
            $result.status | Should -Be Unchanged
        }

        It "Should handle an empty currentList" {
            Mock -CommandName List-WITTags { return @() }

            $result = Get-AzDoWIPTags -ProjectName "TestProject" -WorkItemTrackingTagList @('Tag1') -Ensure ([Ensure]::Absent)
            $result.status | Should -Be Unchanged
        }
    }

    Context "When Ensure is Present" {

        It "Should be handled when no tags need to be added or deleted" {
            $result = Get-AzDoWIPTags -ProjectName "TestProject" -WorkItemTrackingTagList @('Tag1', 'Tag2') -Ensure ([Ensure]::Present)
            $result.status | Should -Be Unchanged
        }

        It "Should handle when no tags are returned from List-WITTags" {
            Mock -CommandName List-WITTags { return @() }

            $result = Get-AzDoWIPTags -ProjectName "TestProject" -WorkItemTrackingTagList @('Tag1', 'Tag2') -Ensure ([Ensure]::Present)
            $result.status | Should -Be NotFound
        }

        It "Should handle when no tags are defined in the current state" {
            Mock -CommandName List-WITTags { return @() }

            $result = Get-AzDoWIPTags -ProjectName "TestProject" -WorkItemTrackingTagList @() -Ensure ([Ensure]::Present)
            $result.status | Should -Be Unchanged
        }

        It "Should set status to Changed when tags need to be added and deleted" {
            $result = Get-AzDoWIPTags -ProjectName "TestProject" -WorkItemTrackingTagList @('Tag3') -Ensure ([Ensure]::Present)
            $result.status | Should -Be Changed
        }

        It "Should set status to NotFound when tags need to be added" {
            $result = Get-AzDoWIPTags -ProjectName "TestProject" -WorkItemTrackingTagList @('Tag3', 'Tag4') -Ensure ([Ensure]::Present)
            $result.status | Should -Be Changed
        }

        It "Should handle a mix of existing and non-existing tags" {
            $result = Get-AzDoWIPTags -ProjectName "TestProject" -WorkItemTrackingTagList @('Tag1', 'Tag3') -Ensure ([Ensure]::Present)
            $result.status | Should -Be Changed
        }

        It "Should handle empty WorkItemTrackingTagList" {
            $result = Get-AzDoWIPTags -ProjectName "TestProject" -WorkItemTrackingTagList @() -Ensure ([Ensure]::Present)
            $result.status | Should -Be Missing
        }
    }

    Context "Edge Cases" {
        It "Should handle all tags present in current state" {
            $result = Get-AzDoWIPTags -ProjectName "TestProject" -WorkItemTrackingTagList @('Tag1', 'Tag2') -Ensure ([Ensure]::Present)
            $result.status | Should -Be Unchanged
        }

        It "Should handle completely new set of tags" {
            $result = Get-AzDoWIPTags -ProjectName "TestProject" -WorkItemTrackingTagList @('Tag3', 'Tag4', 'Tag5') -Ensure ([Ensure]::Present)
            $result.status | Should -Be Changed
        }

        It "Should handle an empty project name gracefully" {
            { Get-AzDoWIPTags -ProjectName "" -WorkItemTrackingTagList @('Tag1') -Ensure ([Ensure]::Present) } | Should -Throw
        }
    }
}
