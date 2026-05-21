<#
    .DESCRIPTION
        This example shows how to remove a task group from an Azure DevOps project.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoTaskGroup 'RemoveAzDoTaskGroup'
        {
            Ensure        = 'Absent'
            ProjectName   = 'MyProject'
            TaskGroupName = 'MyBuildTaskGroup'
        }
    }
}
