<#
    .DESCRIPTION
        This example shows how to create a static test suite in a test plan.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoTestSuite 'AddAzDoTestSuite'
        {
            Ensure      = 'Present'
            ProjectName = 'MyProject'
            PlanName    = 'Sprint 1 Regression'
            Path        = 'Regression'
            SuiteType   = 'StaticTestSuite'
        }
    }
}
