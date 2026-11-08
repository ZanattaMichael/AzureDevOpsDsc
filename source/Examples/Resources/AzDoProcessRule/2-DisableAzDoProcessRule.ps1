<#
    .DESCRIPTION
        This example switches off a rule inherited from the parent process.

        Inherited rules cannot be deleted - disabling is the supported way to turn one off.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

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
