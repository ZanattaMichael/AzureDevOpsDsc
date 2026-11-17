<#
    .DESCRIPTION
        This example shows how to remove a static test suite in a test plan.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoTestSuite 'RemoveAzDoTestSuite'
        {
            Ensure      = 'Absent'
            ProjectName = 'MyProject'
            PlanName    = 'Sprint 1 Regression'
            Path        = 'Regression'
        }
    }
}
