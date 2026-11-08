<#
    .DESCRIPTION
        This example adds a user to the organization with a Basic access level.

        Adding a user consumes a license. For licensing at scale, prefer AzDoGroupEntitlement,
        which applies an access level to every member of a group.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

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
