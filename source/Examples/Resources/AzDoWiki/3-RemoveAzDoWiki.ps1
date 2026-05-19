<#
    .DESCRIPTION
        This example shows how to remove a wiki from an Azure DevOps project.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoWiki 'RemoveAzDoWiki'
        {
            Ensure      = 'Absent'
            ProjectName = 'MyProject'
            WikiName    = 'MyProjectWiki'
        }
    }
}
