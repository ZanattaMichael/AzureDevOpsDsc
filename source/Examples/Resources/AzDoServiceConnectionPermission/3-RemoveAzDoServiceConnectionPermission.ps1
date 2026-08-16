<#
    .DESCRIPTION
        This example shows how to remove permissions on a service connection in an Azure DevOps project.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoServiceConnectionPermission 'RemoveAzDoServiceConnectionPermission'
        {
            Ensure         = 'Absent'
            ProjectName    = 'MyProject'
            ConnectionName = 'MyAzureServiceConnection'
            GroupName      = '[MyProject]\Contributors'
        }
    }
}
