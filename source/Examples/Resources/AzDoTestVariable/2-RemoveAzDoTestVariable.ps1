<#
    .DESCRIPTION
        This example shows how to remove a test configuration variable.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoTestVariable 'RemoveAzDoTestVariable'
        {
            Ensure      = 'Absent'
            ProjectName = 'MyProject'
            Name        = 'Browser'
        }
    }
}
