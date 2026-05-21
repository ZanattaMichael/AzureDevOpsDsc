<#
    .DESCRIPTION
        This example shows how to update a task group in an Azure DevOps project.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoTaskGroup 'UpdateAzDoTaskGroup'
        {
            Ensure        = 'Present'
            ProjectName   = 'MyProject'
            TaskGroupName = 'MyBuildTaskGroup'
            Description   = 'Reusable build steps for .NET and Node.js projects'
            Category      = 'Build'
        }
    }
}
