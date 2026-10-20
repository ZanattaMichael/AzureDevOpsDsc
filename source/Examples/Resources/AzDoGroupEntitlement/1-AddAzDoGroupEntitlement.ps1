<#
    .DESCRIPTION
        This example licenses every member of a group with a Basic access level.

        Group licensing rules are how access levels are managed at scale - AzDoUserEntitlement
        covers one user at a time.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoGroupEntitlement 'LicenseDevelopers'
        {
            Ensure             = 'Present'
            GroupDisplayName   = 'Contoso Developers'
            AccountLicenseType = 'express'
        }
    }
}
