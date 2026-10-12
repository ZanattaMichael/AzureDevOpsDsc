<#
    .DESCRIPTION
        This example shows how to update the description and refresh interval of an
        existing team dashboard. The widgets on the dashboard are left as they are.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

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
