<#
    .DESCRIPTION
        This example shows how to create a project wiki in an Azure DevOps project.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoWiki 'AddAzDoWiki'
        {
            Ensure      = 'Present'
            ProjectName = 'MyProject'
            WikiName    = 'MyProjectWiki'
            WikiType    = 'projectWiki'
        }
    }
}
