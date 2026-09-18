<#
    .DESCRIPTION
        This example removes a group licensing rule.

        Removing the rule does not remove anyone from the organization. Members keep any license
        held directly or granted by another rule.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoGroupEntitlement 'RemoveDeveloperLicensing'
        {
            Ensure           = 'Absent'
            GroupDisplayName = 'Contoso Developers'
        }
    }
}
