<#
    .DESCRIPTION
        This example shows how to update project-level permissions for a group in Azure DevOps.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoProjectPermission 'UpdateAzDoProjectPermission'
        {
            Ensure      = 'Present'
            ProjectName = 'MyProject'
            GroupName   = '[MyProject]\Contributors'
            isInherited = $false
            Permissions = @(
                @{ Permission = 'GENERIC_READ'; Access = 'Allow' }
                @{ Permission = 'GENERIC_WRITE'; Access = 'Allow' }
                @{ Permission = 'DELETE'; Access = 'Deny' }
            )
        }
    }
}
