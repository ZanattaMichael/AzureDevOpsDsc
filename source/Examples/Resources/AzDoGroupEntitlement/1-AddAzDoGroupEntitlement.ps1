<#
    .DESCRIPTION
        This example licenses every member of a group with a Basic access level.

        Group licensing rules are how access levels are managed at scale - AzDoUserEntitlement
        covers one user at a time.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

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
