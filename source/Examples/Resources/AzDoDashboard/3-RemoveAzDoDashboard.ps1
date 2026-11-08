<#
    .DESCRIPTION
        This example shows how to remove a team dashboard and the widgets on it.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

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
