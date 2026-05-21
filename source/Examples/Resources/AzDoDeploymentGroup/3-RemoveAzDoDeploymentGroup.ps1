<#
    .DESCRIPTION
        This example shows how to remove a deployment group from an Azure DevOps project.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoDeploymentGroup 'RemoveAzDoDeploymentGroup'
        {
            Ensure              = 'Absent'
            ProjectName         = 'MyProject'
            DeploymentGroupName = 'ProductionServers'
        }
    }
}
