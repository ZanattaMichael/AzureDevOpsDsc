<#
    .DESCRIPTION
        This example shows how to set role-based permissions on an Artifact feed.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

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