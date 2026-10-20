<#
    .DESCRIPTION
        This example shows how to remove permissions on an agent pool.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

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