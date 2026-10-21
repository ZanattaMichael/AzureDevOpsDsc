<#
    .DESCRIPTION
        This example shows how to create a view on an Azure Artifacts feed.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

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
