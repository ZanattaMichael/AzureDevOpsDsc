<#
    .DESCRIPTION
        This example shows how to create a shared work item query in an Azure DevOps project.

        The query's parent folder must already exist - declare it with AzDoQueryFolder and use
        DependsOn.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoQueryFolder 'AddPlatformFolder'
        {
            Ensure      = 'Present'
            ProjectName = 'MyProject'
            Path        = 'Shared Queries/Platform'
        }

        AzDoWorkItemQuery 'AddActiveBugsQuery'
        {
            Ensure      = 'Present'
            ProjectName = 'MyProject'
            Path        = 'Shared Queries/Platform/Active Bugs'
            Wiql        = "SELECT [System.Id] FROM WorkItems WHERE [System.TeamProject] = @project AND [System.WorkItemType] = 'Bug' AND [System.State] = 'Active'"
            Columns     = @('System.Id', 'System.Title', 'System.State', 'System.AssignedTo')
            DependsOn   = '[AzDoQueryFolder]AddPlatformFolder'
        }
    }
}
