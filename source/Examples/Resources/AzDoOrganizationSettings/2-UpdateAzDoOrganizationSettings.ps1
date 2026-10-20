<#
    .DESCRIPTION
        This example shows how to update organization-level settings in Azure DevOps.
#>

$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -SecureStringPersonalAccessToken $SecureStringPAT

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    node localhost
    {
        AzDoOrganizationSettings 'UpdateAzDoOrganizationSettings'
        {
            Ensure                     = 'Present'
            OrganizationName           = 'test-organization'
            AllowPublicProjects        = $false
            AllowExternalGuestAccess   = $true
            EnableOAuthAuthentication  = $true
            EnableSSHAuthentication    = $false
            DisallowAadGuestUserPolicy = $true
        }
    }
}
