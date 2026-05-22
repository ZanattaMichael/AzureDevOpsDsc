<#
    .DESCRIPTION
        This example shows how to grant permissions on an agent pool.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoAgentPoolPermission 'AddAgentPoolPermission'
        {
            Ensure      = 'Present'
            PoolName    = 'MyPool'
            GroupName   = 'MyGroup'
            isInherited = $true
            Permissions = @(
                @{ Permission = 'Use'; Access = 'Allow' }
            )
        }
    }
}