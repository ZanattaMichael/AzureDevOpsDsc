<#
    .DESCRIPTION
        This example shows how to remove a member from a team in an Azure DevOps project.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoTeamMember 'RemoveAzDoTeamMember'
        {
            Ensure      = 'Absent'
            ProjectName = 'MyProject'
            TeamName    = 'Frontend Team'
            MemberName  = 'user@example.com'
        }
    }
}
