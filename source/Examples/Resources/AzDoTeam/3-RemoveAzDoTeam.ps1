<#
    .DESCRIPTION
        This example shows how to remove a team from an Azure DevOps project.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoTeam 'RemoveAzDoTeam'
        {
            Ensure      = 'Absent'
            ProjectName = 'MyProject'
            TeamName    = 'Frontend Team'
        }
    }
}
