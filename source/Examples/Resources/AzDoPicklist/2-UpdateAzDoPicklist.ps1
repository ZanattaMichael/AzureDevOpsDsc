<#
    .DESCRIPTION
        This example manages a picklist's values.

        Items are replaced wholesale - the update endpoint takes the complete list, so anything
        omitted is removed. Removing a value does not rewrite work items that already carry it;
        they keep it, and it then fails validation on the next edit.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoPicklist 'Severity'
        {
            Ensure       = 'Present'
            PicklistName = 'Severity'
            Items        = @('1 - Critical', '2 - High', '3 - Medium', '4 - Low', '5 - Trivial')
            IsSuggested  = $false
        }
    }
}
