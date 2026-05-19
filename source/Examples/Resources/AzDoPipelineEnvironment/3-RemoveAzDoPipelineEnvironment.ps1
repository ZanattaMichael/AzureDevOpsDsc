<#
    .DESCRIPTION
        This example shows how to remove a pipeline environment from an Azure DevOps project.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoPipelineEnvironment 'RemoveAzDoPipelineEnvironment'
        {
            Ensure          = 'Absent'
            ProjectName     = 'MyProject'
            EnvironmentName = 'Production'
        }
    }
}
