<#
    .DESCRIPTION
        This example shows how to update permissions on an agent pool.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

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