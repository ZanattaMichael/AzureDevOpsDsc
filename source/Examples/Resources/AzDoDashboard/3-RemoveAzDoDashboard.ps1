<#
    .DESCRIPTION
        This example shows how to remove a team dashboard and the widgets on it.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoDashboard 'RemoveAzDoDashboard'
        {
            Ensure        = 'Absent'
            DashboardName = 'Sprint Overview'
            ProjectName   = 'MyProject'
            TeamName      = 'MyProject Team'
        }
    }
}
