<#
    .DESCRIPTION
        This example shows how to remove permissions from an Azure DevOps group.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoGroupPermission 'RemoveAzDoGroupPermission'
        {
            Ensure    = 'Absent'
            GroupName = '[MyProject]\Readers'
        }
    }
}
