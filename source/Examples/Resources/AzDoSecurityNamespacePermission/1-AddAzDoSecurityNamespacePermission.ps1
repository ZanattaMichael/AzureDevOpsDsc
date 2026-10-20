<#
    .DESCRIPTION
        This example shows how to grant permissions within a security namespace in Azure DevOps.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoSecurityNamespacePermission 'AddAzDoSecurityNamespacePermission'
        {
            Ensure            = 'Present'
            SecurityNamespace = 'Build'
            Token             = 'repoV2/00000000-0000-0000-0000-000000000001'
            GroupName         = '[MyProject]\Contributors'
            isInherited       = $true
            Permissions       = @(
                @{ Permission = 'ViewBuilds'; Access = 'Allow' }
                @{ Permission = 'QueueBuilds'; Access = 'Allow' }
            )
        }
    }
}
