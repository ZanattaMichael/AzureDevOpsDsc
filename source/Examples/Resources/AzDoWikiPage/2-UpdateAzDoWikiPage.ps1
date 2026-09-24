<#
    .DESCRIPTION
        This example shows how to update a wiki page's content from a local file and set its
        position among its sibling pages.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

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
