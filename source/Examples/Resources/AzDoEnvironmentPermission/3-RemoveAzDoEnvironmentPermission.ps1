<#
    .DESCRIPTION
        This example shows how to remove permissions on a pipeline environment in an Azure DevOps project.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoEnvironmentPermission 'RemoveAzDoEnvironmentPermission'
        {
            Ensure          = 'Absent'
            ProjectName     = 'MyProject'
            EnvironmentName = 'Production'
            GroupName       = '[MyProject]\Contributors'
        }
    }
}
