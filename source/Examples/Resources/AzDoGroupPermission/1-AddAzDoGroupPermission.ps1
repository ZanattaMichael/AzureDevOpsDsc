<#
    .DESCRIPTION
        This example shows how to grant permissions on an Azure DevOps group.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoGroupPermission 'AddAzDoGroupPermission'
        {
            Ensure      = 'Present'
            GroupName   = '[MyProject]\Readers'
            isInherited = $true
            Permissions = @(
                @{ Permission = 'GENERIC_READ'; Access = 'Allow' }
            )
        }
    }
}
