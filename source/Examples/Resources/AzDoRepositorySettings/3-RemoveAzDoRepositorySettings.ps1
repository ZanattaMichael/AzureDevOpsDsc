<#
    .DESCRIPTION
        This example shows how to reset repository settings to defaults in an Azure DevOps project.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoRepositorySettings 'RemoveAzDoRepositorySettings'
        {
            Ensure         = 'Absent'
            ProjectName    = 'MyProject'
            RepositoryName = 'MyRepository'
        }
    }
}
