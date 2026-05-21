<#
    .DESCRIPTION
        This example shows how to remove permissions on a variable group in an Azure DevOps project.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoVariableGroupPermission 'RemoveAzDoVariableGroupPermission'
        {
            Ensure            = 'Absent'
            ProjectName       = 'MyProject'
            VariableGroupName = 'MyVariableGroup'
            GroupName         = '[MyProject]\Contributors'
        }
    }
}
