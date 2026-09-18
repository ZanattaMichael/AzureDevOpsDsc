<#
    .DESCRIPTION
        This example makes a field required in a particular state.

        Conditions and actions are written as the API models them, because the vocabulary is large
        and grows between API versions.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoProcessRule 'SeverityRequiredWhenActive'
        {
            Ensure           = 'Present'
            ProcessName      = 'Contoso Agile'
            WorkItemTypeName = 'Incident'
            RuleName         = 'Severity required when active'
            Conditions       = @(
                @{ conditionType = 'when'; field = 'System.State'; value = 'Active' }
            )
            Actions          = @(
                @{ actionType = 'makeRequired'; targetField = 'Custom.Severity' }
            )
        }
    }
}
