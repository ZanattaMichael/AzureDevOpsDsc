<#
    .DESCRIPTION
        This example shows how to change a group's organization-level permissions.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoOrganizationPermission 'UpdateAzDoOrganizationPermission'
        {
            Ensure      = 'Present'
            GroupName   = '[test-organization]\Project Creators'
            Permissions = @(
                @{
                    Identity   = '[test-organization]\Project Creators'
                    Permission = @{ 'Create new projects' = 'Deny'; 'Manage enterprise policies' = 'Allow' }
                }
            )
        }
    }
}
