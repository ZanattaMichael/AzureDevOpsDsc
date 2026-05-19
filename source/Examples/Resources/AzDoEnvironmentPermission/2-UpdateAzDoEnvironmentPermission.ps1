<#
    .DESCRIPTION
        This example shows how to update permissions on a pipeline environment in an Azure DevOps project.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoEnvironmentPermission 'UpdateAzDoEnvironmentPermission'
        {
            Ensure          = 'Present'
            ProjectName     = 'MyProject'
            EnvironmentName = 'Production'
            GroupName       = '[MyProject]\Contributors'
            isInherited     = $false
            Permissions     = @(
                @{ Permission = 'View'; Access = 'Allow' }
                @{ Permission = 'Manage'; Access = 'Deny' }
            )
        }
    }
}
