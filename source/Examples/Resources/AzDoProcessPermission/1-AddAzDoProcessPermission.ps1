<#
    .DESCRIPTION
        This example allows a group to create and edit inherited processes.

        'AllProcesses' targets the organization-wide process root rather than one process.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoProcessPermission 'AllowCreateProcesses'
        {
            Ensure      = 'Present'
            ProcessName = 'AllProcesses'
            isInherited = $true
            Permissions = @(
                @{
                    Identity   = '[MyOrg]\Process Authors'
                    Permission = @{
                        'Create' = 'Allow'
                        'Edit'   = 'Allow'
                    }
                }
            )
        }
    }
}
