<#
    .DESCRIPTION
        This example shows how to create a dashboard for a team in an existing project.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoDashboard 'AddAzDoDashboard'
        {
            Ensure        = 'Present'
            DashboardName = 'Sprint Overview'
            ProjectName   = 'MyProject'
            TeamName      = 'MyProject Team'
            Description   = 'Burndown and open bugs for the current sprint'
        }
    }
}
