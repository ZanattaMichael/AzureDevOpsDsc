<#
    .DESCRIPTION
        This example sets a project's run and artifact retention policy.

        Only the settings you specify are compared and applied; any omitted here are left
        untouched. Each value is validated against the organization's own live min/max range
        for that setting - an out-of-range value is refused rather than silently clamped or
        ignored.

        The classic-pipeline-era 'maximum retention policy' / 'default retention policy' values
        at `_apis/build/settings` are not managed by this resource - see docs/ResourceRoadmap.md.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoBuildRetentionSettings 'ProjectRetention'
        {
            Ensure                         = 'Present'
            ProjectName                    = 'MyProject'
            DaysToKeepRuns                 = 30
            DaysToKeepArtifacts            = 14
            DaysToKeepPullRequestRuns      = 10
            RunsToRetainPerProtectedBranch = 3
        }
    }
}
