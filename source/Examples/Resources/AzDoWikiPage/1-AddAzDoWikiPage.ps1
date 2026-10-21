<#
    .DESCRIPTION
        This example shows how to create a wiki page with inline Markdown content in an
        existing project wiki.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoWikiPage 'AddAzDoWikiPage'
        {
            Ensure      = 'Present'
            ProjectName = 'MyProject'
            WikiName    = 'MyProjectWiki'
            Path        = '/Runbooks/On-call'
            Content     = "# On-call`n`nCall the on-call engineer."
        }
    }
}
