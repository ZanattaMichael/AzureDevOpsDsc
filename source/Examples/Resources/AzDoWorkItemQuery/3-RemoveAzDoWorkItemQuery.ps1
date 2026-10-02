<#
    .DESCRIPTION
        This example shows how to remove a shared work item query.

        Azure DevOps moves a deleted query to the project's query recycle bin rather than
        destroying it outright.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoWorkItemQuery 'RemoveActiveBugsQuery'
        {
            Ensure      = 'Absent'
            ProjectName = 'MyProject'
            Path        = 'Shared Queries/Platform/Active Bugs'
        }
    }
}
