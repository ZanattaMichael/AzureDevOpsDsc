<#
    .DESCRIPTION
        This example shows how to create a deployment group in an Azure DevOps project.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoDeploymentGroup 'AddAzDoDeploymentGroup'
        {
            Ensure              = 'Present'
            ProjectName         = 'MyProject'
            DeploymentGroupName = 'ProductionServers'
            Description         = 'Deployment group for production web servers'
            Tags                = @('Production', 'Windows', 'IIS')
        }
    }
}
