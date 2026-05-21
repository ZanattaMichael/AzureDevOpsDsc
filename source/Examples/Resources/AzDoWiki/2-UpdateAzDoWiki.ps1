<#
    .DESCRIPTION
        This example shows how to create a code wiki linked to a repository in an Azure DevOps project.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoWiki 'UpdateAzDoWiki'
        {
            Ensure         = 'Present'
            ProjectName    = 'MyProject'
            WikiName       = 'MyCodeWiki'
            WikiType       = 'codeWiki'
            RepositoryName = 'MyRepository'
            MappedPath     = '/docs'
            Version        = 'main'
        }
    }
}
