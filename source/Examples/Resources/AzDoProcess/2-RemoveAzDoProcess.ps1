<#
    .DESCRIPTION
        This example removes an inherited process.

        A process still in use by a project cannot be deleted, and neither can a system process.
        Move the projects to another process first.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoProcess 'RemoveContosoAgile'
        {
            Ensure      = 'Absent'
            ProcessName = 'Contoso Agile'
        }
    }
}
