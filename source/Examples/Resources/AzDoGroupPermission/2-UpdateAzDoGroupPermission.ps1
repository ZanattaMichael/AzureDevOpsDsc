<#
    .DESCRIPTION
        This example shows how to update permissions on an Azure DevOps group.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoGroupPermission 'UpdateAzDoGroupPermission'
        {
            Ensure      = 'Present'
            GroupName   = '[MyProject]\Readers'
            isInherited = $false
            Permissions = @(
                @{ Permission = 'GENERIC_READ'; Access = 'Allow' }
                @{ Permission = 'GENERIC_WRITE'; Access = 'Deny' }
            )
        }
    }
}
