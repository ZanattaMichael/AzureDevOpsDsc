<#
    .DESCRIPTION
        This example shows how to add a different member to a team in an Azure DevOps project.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoTeamMember 'UpdateAzDoTeamMember'
        {
            Ensure      = 'Present'
            ProjectName = 'MyProject'
            TeamName    = 'Frontend Team'
            MemberName  = 'anotheruser@example.com'
        }
    }
}
