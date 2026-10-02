<#
    .DESCRIPTION
        This example shows how to manage a query's WIQL, columns and sort order.

        Changes are applied in place. The query keeps its id, so dashboard widgets, delivery
        plans and ACL tokens that reference the query keep working across an update.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoWorkItemQuery 'UpdateActiveBugsQuery'
        {
            Ensure      = 'Present'
            ProjectName = 'MyProject'
            Path        = 'Shared Queries/Platform/Active Bugs'
            Wiql        = "SELECT [System.Id] FROM WorkItems WHERE [System.TeamProject] = @project AND [System.WorkItemType] = 'Bug' AND [System.State] <> 'Closed'"
            QueryType   = 'flat'
            Columns     = @('System.Id', 'System.Title', 'System.State')
            SortColumns = @(
                @{ Field = 'System.ChangedDate'; Descending = $true }
            )
        }
    }
}
