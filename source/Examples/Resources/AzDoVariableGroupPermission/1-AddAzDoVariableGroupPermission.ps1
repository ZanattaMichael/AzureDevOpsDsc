<#
    .DESCRIPTION
        This example shows how to grant permissions on a variable group in an Azure DevOps project.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoVariableGroupPermission 'AddAzDoVariableGroupPermission'
        {
            Ensure            = 'Present'
            ProjectName       = 'MyProject'
            VariableGroupName = 'MyVariableGroup'
            GroupName         = '[MyProject]\Contributors'
            isInherited       = $true
            Permissions       = @(
                @{ Permission = 'Use'; Access = 'Allow' }
            )
        }
    }
}
