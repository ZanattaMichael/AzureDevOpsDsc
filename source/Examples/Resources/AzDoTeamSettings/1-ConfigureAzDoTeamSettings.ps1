<#
    .DESCRIPTION
        This example shows how to configure the iteration and area paths for an Azure DevOps team.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoTeamSettings 'ConfigureFrontendTeam'
        {
            Ensure               = 'Present'
            ProjectName          = 'MyProject'
            TeamName             = 'Frontend Team'

            # Iteration configuration
            BacklogIterationPath = 'MyProject'
            DefaultIterationPath = 'MyProject\Sprint 1'
            IterationPaths       = @('MyProject\Sprint 1', 'MyProject\Sprint 2')

            # Area-path configuration
            DefaultAreaPath      = 'MyProject\Frontend'
            AreaPaths            = @('MyProject\Frontend', 'MyProject\Frontend\Web')

            # General team settings
            WorkingDays          = @('monday', 'tuesday', 'wednesday', 'thursday', 'friday')
            BugsBehavior         = 'asRequirements'
        }
    }
}
