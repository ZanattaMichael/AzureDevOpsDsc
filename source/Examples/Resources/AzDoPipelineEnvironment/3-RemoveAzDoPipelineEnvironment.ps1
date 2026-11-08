<#
    .DESCRIPTION
        This example shows how to remove a pipeline environment from an Azure DevOps project.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoPipelineEnvironment 'RemoveAzDoPipelineEnvironment'
        {
            Ensure          = 'Absent'
            ProjectName     = 'MyProject'
            EnvironmentName = 'Production'
        }
    }
}
