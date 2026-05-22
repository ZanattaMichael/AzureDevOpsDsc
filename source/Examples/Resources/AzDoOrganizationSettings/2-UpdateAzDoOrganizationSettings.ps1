<#
    .DESCRIPTION
        This example shows how to update organization-level settings in Azure DevOps.
#>

New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

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
