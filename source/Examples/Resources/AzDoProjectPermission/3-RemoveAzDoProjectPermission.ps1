<#
    .DESCRIPTION
        This example shows how to remove project-level permissions from a group in Azure DevOps.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoProjectPermission 'RemoveAzDoProjectPermission'
        {
            Ensure      = 'Absent'
            ProjectName = 'MyProject'
            GroupName   = '[MyProject]\Contributors'
        }
    }
}
