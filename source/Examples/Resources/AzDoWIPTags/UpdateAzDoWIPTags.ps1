<#
    .DESCRIPTION
        This example shows how to update Tags
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{

    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoWIPTags 'AddProjectWIPTags' {
            ProjectName        = 'SampleProject'
            WorkItemTrackingTagList = @('Blocked', 'Need More Info', 'Ready for Review')
        }
    }
}
