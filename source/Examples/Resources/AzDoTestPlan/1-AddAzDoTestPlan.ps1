<#
    .DESCRIPTION
        This example shows how to create a test plan.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoTestPlan 'AddAzDoTestPlan'
        {
            Ensure      = 'Present'
            ProjectName = 'MyProject'
            Name        = 'Sprint 1 Regression'
            AreaPath    = 'MyProject'
            Iteration   = 'MyProject\Sprint 1'
            State       = 'Active'
        }
    }
}
