<#
    .DESCRIPTION
        This example shows how to update a wiki page's content from a local file and set its
        position among its sibling pages.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoWikiPage 'UpdateAzDoWikiPage'
        {
            Ensure      = 'Present'
            ProjectName = 'MyProject'
            WikiName    = 'MyProjectWiki'
            Path        = '/Runbooks/On-call'
            ContentPath = 'C:\Docs\OnCallRunbook.md'
            Order       = 0
        }
    }
}
