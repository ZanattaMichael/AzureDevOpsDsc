<#
    .DESCRIPTION
        This example shows how to update analytics permissions for a group in Azure DevOps.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoAnalyticsPermission 'UpdateAzDoAnalyticsPermission'
        {
            Ensure      = 'Present'
            ProjectName = 'MyProject'
            GroupName   = '[MyProject]\Contributors'
            isInherited = $false
            Permissions = @(
                @{ Permission = 'Read'; Access = 'Allow' }
            )
        }
    }
}
