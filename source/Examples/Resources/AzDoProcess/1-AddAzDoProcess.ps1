<#
    .DESCRIPTION
        This example creates an inherited process.

        An inherited process is the prerequisite for any process customization: the system
        processes (Agile, Scrum, Basic, CMMI) are read-only, so customizing work item types,
        fields, states or rules means deriving a process first.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoProcess 'ContosoAgile'
        {
            Ensure            = 'Present'
            ProcessName       = 'Contoso Agile'
            ParentProcessName = 'Agile'
            Description       = 'Agile process customised for Contoso'
        }
    }
}
