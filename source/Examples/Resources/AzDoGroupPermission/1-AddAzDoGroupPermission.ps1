<#
    .DESCRIPTION
        This example shows how to grant permissions on an Azure DevOps group.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

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
