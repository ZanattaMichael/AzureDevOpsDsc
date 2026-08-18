<#
    .DESCRIPTION
        This example shows how to remove permissions from an Azure DevOps group.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoGroupPermission 'RemoveAzDoGroupPermission'
        {
            Ensure    = 'Absent'
            GroupName = '[MyProject]\Readers'
        }
    }
}
