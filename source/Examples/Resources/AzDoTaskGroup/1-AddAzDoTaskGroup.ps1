<#
    .DESCRIPTION
        This example shows how to create a task group in an Azure DevOps project.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoTaskGroup 'AddAzDoTaskGroup'
        {
            Ensure        = 'Present'
            ProjectName   = 'MyProject'
            TaskGroupName = 'MyBuildTaskGroup'
            Description   = 'Reusable build steps for .NET projects'
            Category      = 'Build'
        }
    }
}
