<#
    .DESCRIPTION
        This example switches off a rule inherited from the parent process.

        Inherited rules cannot be deleted - disabling is the supported way to turn one off.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoProcessRule 'DisableInheritedRule'
        {
            Ensure           = 'Present'
            ProcessName      = 'Contoso Agile'
            WorkItemTypeName = 'Bug'
            RuleName         = 'Inherited rule name'
            IsDisabled       = $true
        }
    }
}
