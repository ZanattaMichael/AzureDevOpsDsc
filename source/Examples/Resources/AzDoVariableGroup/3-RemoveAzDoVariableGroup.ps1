<#
    .DESCRIPTION
        This example shows how to remove a variable group from an Azure DevOps project.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoVariableGroup 'RemoveAzDoVariableGroup'
        {
            Ensure            = 'Absent'
            ProjectName       = 'MyProject'
            VariableGroupName = 'MyVariableGroup'
        }
    }
}
