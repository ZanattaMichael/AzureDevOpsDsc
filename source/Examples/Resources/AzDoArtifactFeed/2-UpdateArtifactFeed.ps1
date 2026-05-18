<#
    .DESCRIPTION
        This example shows how to update an Azure Artifacts feed.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoArtifactFeed 'UpdateArtifactFeed'
        {
            Ensure          = 'Present'
            ProjectName     = 'MyProject'
            FeedName        = 'MyFeed'
            Description     = 'Updated package feed'
            BadgesEnabled   = $true
            UpstreamEnabled = $false
        }
    }
}