<#
    .DESCRIPTION
        This example shows how to remove an Azure Artifacts feed.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoArtifactFeed 'RemoveArtifactFeed'
        {
            Ensure      = 'Absent'
            ProjectName = 'MyProject'
            FeedName    = 'MyFeed'
        }
    }
}