<#
    .DESCRIPTION
        This example shows how to create a view on an Azure Artifacts feed.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoArtifactFeedView 'AddReleaseView'
        {
            Ensure         = 'Present'
            ProjectName    = 'MyProject'
            FeedName       = 'MyFeed'
            ViewName       = 'Release'
            ViewType       = 'release'
            ViewVisibility = 'organization'
        }
    }
}
