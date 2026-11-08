<#
    .DESCRIPTION
        This example removes a group licensing rule.

        Removing the rule does not remove anyone from the organization. Members keep any license
        held directly or granted by another rule.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

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
