<#
    .DESCRIPTION
        This example shows how to grant permissions on an agent pool.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

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