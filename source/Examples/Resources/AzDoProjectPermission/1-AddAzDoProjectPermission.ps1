<#
    .DESCRIPTION
        This example shows how to grant project-level permissions to a group in Azure DevOps.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoProjectPermission 'AddAzDoProjectPermission'
        {
            Ensure      = 'Present'
            ProjectName = 'MyProject'
            GroupName   = '[MyProject]\Contributors'
            isInherited = $true
            Permissions = @(
                @{ Permission = 'GENERIC_READ'; Access = 'Allow' }
                @{ Permission = 'GENERIC_WRITE'; Access = 'Allow' }
            )
        }
    }
}
