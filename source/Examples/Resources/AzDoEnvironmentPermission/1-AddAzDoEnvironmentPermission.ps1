<#
    .DESCRIPTION
        This example shows how to grant permissions on a pipeline environment in an Azure DevOps project.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoEnvironmentPermission 'AddAzDoEnvironmentPermission'
        {
            Ensure          = 'Present'
            ProjectName     = 'MyProject'
            EnvironmentName = 'Production'
            GroupName       = '[MyProject]\Contributors'
            isInherited     = $true
            Permissions     = @(
                @{ Permission = 'View'; Access = 'Allow' }
            )
        }
    }
}
