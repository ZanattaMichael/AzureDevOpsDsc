<#
    .DESCRIPTION
        This example shows how to clear a group's organization-level permissions. Other identities' permissions are left as they are.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoOrganizationPermission 'RemoveAzDoOrganizationPermission'
        {
            Ensure      = 'Absent'
            GroupName   = '[test-organization]\Project Creators'
            Permissions = @(
                @{
                    Identity   = '[test-organization]\Project Creators'
                    Permission = @{ 'Create new projects' = 'Allow' }
                }
            )
        }
    }
}
