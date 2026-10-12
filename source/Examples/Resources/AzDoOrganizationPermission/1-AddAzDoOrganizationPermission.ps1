<#
    .DESCRIPTION
        This example shows how to allow a group to create projects in an Azure DevOps organization.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoOrganizationPermission 'AddAzDoOrganizationPermission'
        {
            Ensure      = 'Present'
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
