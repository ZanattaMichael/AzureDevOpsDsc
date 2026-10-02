<#
    .DESCRIPTION
        This example shows how to remove a wiki page. Removing a page that still has sub-pages
        is refused unless AllowRecursiveDelete is set, since removal deletes them too.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoWikiPage 'RemoveAzDoWikiPage'
        {
            Ensure               = 'Absent'
            ProjectName          = 'MyProject'
            WikiName             = 'MyProjectWiki'
            Path                 = '/Runbooks'
            AllowRecursiveDelete = $true
        }
    }
}
