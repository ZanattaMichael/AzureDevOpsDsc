<#
    .DESCRIPTION
        This example shows how to update permissions on a variable group in an Azure DevOps project.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoVariableGroupPermission 'UpdateAzDoVariableGroupPermission'
        {
            Ensure            = 'Present'
            ProjectName       = 'MyProject'
            VariableGroupName = 'MyVariableGroup'
            GroupName         = '[MyProject]\Contributors'
            isInherited       = $false
            Permissions       = @(
                @{ Permission = 'Use'; Access = 'Allow' }
                @{ Permission = 'Administer'; Access = 'Deny' }
            )
        }
    }
}
