<#
    .DESCRIPTION
        This example shows how to set role-based permissions on an Artifact feed.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoArtifactFeedPermission 'AddArtifactFeedPermission'
        {
            Ensure      = 'Present'
            ProjectName = 'MyProject'
            FeedName    = 'MyFeed'
            Permissions = @(
                @{ identity = 'vsid-of-group'; role = 'Reader' }
            )
        }
    }
}