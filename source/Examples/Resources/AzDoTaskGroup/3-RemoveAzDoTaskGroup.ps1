<#
    .DESCRIPTION
        This example shows how to remove a task group from an Azure DevOps project.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

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
