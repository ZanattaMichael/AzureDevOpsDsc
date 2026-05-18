<#
    .DESCRIPTION
        This example shows how to create an Azure Artifacts feed.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoArtifactFeed 'AddArtifactFeed'
        {
            Ensure          = 'Present'
            ProjectName     = 'MyProject'
            FeedName        = 'MyFeed'
            Description     = 'My package feed'
            BadgesEnabled   = $false
            UpstreamEnabled = $true
        }
    }
}