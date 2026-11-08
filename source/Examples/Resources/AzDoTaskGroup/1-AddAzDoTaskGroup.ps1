<#
    .DESCRIPTION
        This example shows how to create a task group in an Azure DevOps project.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

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
