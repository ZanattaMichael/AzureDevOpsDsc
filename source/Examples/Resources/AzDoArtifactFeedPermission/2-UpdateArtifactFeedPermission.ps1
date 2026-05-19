<#
    .DESCRIPTION
        This example shows how to update role-based permissions on an Artifact feed.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoArtifactFeedPermission 'UpdateArtifactFeedPermission'
        {
            Ensure      = 'Present'
            ProjectName = 'MyProject'
            FeedName    = 'MyFeed'
            Permissions = @(
                @{ identity = 'vsid-of-group'; role = 'Contributor' }
            )
        }
    }
}