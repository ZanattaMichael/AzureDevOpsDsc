<#
    .DESCRIPTION
        This example shows how to remove a test configuration.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoTestConfiguration 'RemoveAzDoTestConfiguration'
        {
            Ensure      = 'Absent'
            ProjectName = 'MyProject'
            Name        = 'Windows 11 + Edge'
        }
    }
}
