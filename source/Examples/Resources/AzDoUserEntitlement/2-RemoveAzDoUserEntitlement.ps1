<#
    .DESCRIPTION
        This example removes a user from the organization, releasing their license.

        A user also covered by a group licensing rule may retain access through that rule.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoUserEntitlement 'RemoveJane'
        {
            Ensure            = 'Absent'
            UserPrincipalName = 'jane@contoso.com'
        }
    }
}
