<#
    .DESCRIPTION
        This example hides an inherited work item type without deleting it.

        Disabling is the reversible alternative to removal: the type stops appearing in pickers
        but existing work items and their history are untouched.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoProcessWorkItemType 'DisableImpediment'
        {
            Ensure           = 'Present'
            ProcessName      = 'Contoso Agile'
            WorkItemTypeName = 'Impediment'
            IsDisabled       = $true
        }
    }
}
