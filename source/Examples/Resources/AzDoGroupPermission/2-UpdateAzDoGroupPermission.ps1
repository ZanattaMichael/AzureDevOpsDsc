<#
    .DESCRIPTION
        This example shows how to update permissions on an Azure DevOps group.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

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
