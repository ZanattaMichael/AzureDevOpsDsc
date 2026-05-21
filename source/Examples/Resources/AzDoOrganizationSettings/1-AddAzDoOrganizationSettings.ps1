<#
    .DESCRIPTION
        This example shows how to configure organization-level settings in Azure DevOps.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoOrganizationSettings 'AddAzDoOrganizationSettings'
        {
            Ensure                     = 'Present'
            OrganizationName           = 'test-organization'
            AllowPublicProjects        = $false
            AllowExternalGuestAccess   = $false
            EnableOAuthAuthentication  = $true
            EnableSSHAuthentication    = $true
            DisallowAadGuestUserPolicy = $false
        }
    }
}
