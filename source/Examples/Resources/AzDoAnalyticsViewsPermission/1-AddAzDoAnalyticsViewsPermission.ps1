<#
    .DESCRIPTION
        This example shows how to deny read access to a shared Analytics view for a group in Azure DevOps.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoAnalyticsViewsPermission 'AddAzDoAnalyticsViewsPermission'
        {
            Ensure      = 'Present'
            ProjectName = 'MyProject'
            GroupName   = '[MyProject]\Contributors'
            isInherited = $false
            Permissions = @(
                @{ Permission = 'Read'; Access = 'Deny' }
            )
        }
    }
}
