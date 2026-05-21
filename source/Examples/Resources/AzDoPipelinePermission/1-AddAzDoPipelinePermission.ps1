<#
    .DESCRIPTION
        This example shows how to grant permissions on a pipeline in an Azure DevOps project.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoPipelinePermission 'AddAzDoPipelinePermission'
        {
            Ensure       = 'Present'
            ProjectName  = 'MyProject'
            PipelineName = 'MyBuildPipeline'
            GroupName    = '[MyProject]\Contributors'
            isInherited  = $true
            Permissions  = @(
                @{ Permission = 'ViewBuilds'; Access = 'Allow' }
                @{ Permission = 'QueueBuilds'; Access = 'Allow' }
            )
        }
    }
}
