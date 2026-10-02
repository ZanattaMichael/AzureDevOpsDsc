<#
    .DESCRIPTION
        This example removes a custom work item type.

        This deletes every work item of that type in every project using the process, which is why
        AllowDestructiveRemove is required. Prefer IsDisabled unless the type really must go.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoProcessWorkItemType 'RemoveIncident'
        {
            Ensure                 = 'Absent'
            ProcessName            = 'Contoso Agile'
            WorkItemTypeName       = 'Incident'
            AllowDestructiveRemove = $true
        }
    }
}
