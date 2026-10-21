<#
    .DESCRIPTION
        This example makes a field required in a particular state.

        Conditions and actions are written as the API models them, because the vocabulary is large
        and grows between API versions.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

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
