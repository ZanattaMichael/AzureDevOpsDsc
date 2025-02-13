<#
    .DESCRIPTION
        This example shows how to add Tags
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{

    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoWIPTags 'AddProjectWIPTags' {
            Ensure             = 'Present'
            ProjectName        = 'SampleProject'
            WorkItemTrackingTagList = @('Blocked', 'Need More Info', 'Ready for Dev', 'Ready for QA', 'Ready for Prod')
        }
    }
}
