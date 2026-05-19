<#
    .DESCRIPTION
        This example shows how to update permissions on an agent pool.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoAgentPoolPermission 'UpdateAgentPoolPermission'
        {
            Ensure      = 'Present'
            PoolName    = 'MyPool'
            GroupName   = 'MyGroup'
            isInherited = $false
            Permissions = @(
                @{ Permission = 'Use';          Access = 'Allow' }
                @{ Permission = 'Administer';   Access = 'Deny' }
            )
        }
    }
}