<#
    .DESCRIPTION
        This example shows how to update the description and refresh interval of an
        existing team dashboard. The widgets on the dashboard are left as they are.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoDashboard 'UpdateAzDoDashboard'
        {
            Ensure          = 'Present'
            DashboardName   = 'Sprint Overview'
            ProjectName     = 'MyProject'
            TeamName        = 'MyProject Team'
            Description     = 'Burndown, velocity and open bugs for the current sprint'
            RefreshInterval = 5
        }
    }
}
