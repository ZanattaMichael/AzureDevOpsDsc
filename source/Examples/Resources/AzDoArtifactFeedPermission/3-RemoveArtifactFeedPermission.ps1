<#
    .DESCRIPTION
        This example shows how to remove permissions from an Artifact feed.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoArtifactFeedPermission 'RemoveArtifactFeedPermission'
        {
            Ensure      = 'Absent'
            ProjectName = 'MyProject'
            FeedName    = 'MyFeed'
        }
    }
}