<#
    .DESCRIPTION
        This example adds a user to the organization with a Basic access level.

        Adding a user consumes a license. For licensing at scale, prefer AzDoGroupEntitlement,
        which applies an access level to every member of a group.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoUserEntitlement 'JaneBasic'
        {
            Ensure             = 'Present'
            UserPrincipalName  = 'jane@contoso.com'
            AccountLicenseType = 'express'
        }
    }
}
