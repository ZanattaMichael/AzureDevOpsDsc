<#
    .DESCRIPTION
        This example creates a picklist - the allowed values behind a custom field of type
        "picklist".

        Picklists are organization-scoped, so one list can back fields in several processes.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoPicklist 'Severity'
        {
            Ensure       = 'Present'
            PicklistName = 'Severity'
            Items        = @('1 - Critical', '2 - High', '3 - Medium', '4 - Low')
        }
    }
}
