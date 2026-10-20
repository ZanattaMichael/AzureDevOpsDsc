<#
    .DESCRIPTION
        This example shows how to remove an Azure Artifacts feed.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

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