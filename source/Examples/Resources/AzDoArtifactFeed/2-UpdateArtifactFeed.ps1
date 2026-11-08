<#
    .DESCRIPTION
        This example shows how to update an Azure Artifacts feed.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

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