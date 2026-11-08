<#
    .DESCRIPTION
        This example shows how to create an Azure Artifacts feed.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

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