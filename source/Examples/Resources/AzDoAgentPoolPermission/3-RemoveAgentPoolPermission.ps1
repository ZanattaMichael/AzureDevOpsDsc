<#
    .DESCRIPTION
        This example shows how to remove permissions on an agent pool.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoAgentPoolPermission 'RemoveAgentPoolPermission'
        {
            Ensure      = 'Absent'
            PoolName    = 'MyPool'
            GroupName   = 'MyGroup'
            isInherited = $true
        }
    }
}