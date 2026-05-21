<#
    .DESCRIPTION
        This example shows how to remove pipeline permissions in an Azure DevOps project.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoPipelinePermission 'RemoveAzDoPipelinePermission'
        {
            Ensure       = 'Absent'
            ProjectName  = 'MyProject'
            PipelineName = 'MyBuildPipeline'
            GroupName    = '[MyProject]\Contributors'
        }
    }
}
