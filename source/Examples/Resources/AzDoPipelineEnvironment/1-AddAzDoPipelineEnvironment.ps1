<#
    .DESCRIPTION
        This example shows how to create a pipeline environment in an Azure DevOps project.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoPipelineEnvironment 'AddAzDoPipelineEnvironment'
        {
            Ensure          = 'Present'
            ProjectName     = 'MyProject'
            EnvironmentName = 'Production'
            Description     = 'Production deployment environment'
        }
    }
}
