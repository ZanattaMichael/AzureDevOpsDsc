<#
    .DESCRIPTION
        This example removes a custom work item type.

        This deletes every work item of that type in every project using the process, which is why
        AllowDestructiveRemove is required. Prefer IsDisabled unless the type really must go.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

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
