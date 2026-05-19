# DSC AzDoOrganizationSettings Resource

# Syntax

``` PowerShell
AzDoOrganizationSettings [string] #ResourceName
{
    OrganizationName               = [String]$OrganizationName
    [ AllowPublicProjects          = [Boolean]$AllowPublicProjects ]
    [ AllowExternalGuestAccess     = [Boolean]$AllowExternalGuestAccess ]
    [ EnableOAuthAuthentication    = [Boolean]$EnableOAuthAuthentication ]
    [ EnableSSHAuthentication      = [Boolean]$EnableSSHAuthentication ]
    [ DisallowAadGuestUserPolicy   = [Boolean]$DisallowAadGuestUserPolicy ]
    [ Ensure                       = [String] {'Present', 'Absent'} ]
}
```

# Common Properties

- __OrganizationName__: The name of the Azure DevOps organization. This is a key property and is not configurable after creation.
- __AllowPublicProjects__: Whether users can create public (anonymous-access) projects. Defaults to organization default.
- __AllowExternalGuestAccess__: Whether external guest users (Azure AD guests) can be added to the organization. Defaults to organization default.
- __EnableOAuthAuthentication__: Whether OAuth authentication is enabled for third-party applications. Defaults to organization default.
- __EnableSSHAuthentication__: Whether SSH authentication is enabled for Git operations. Defaults to organization default.
- __DisallowAadGuestUserPolicy__: Whether the Azure AD guest user policy is disallowed. Defaults to organization default.
- __Ensure__: Specifies whether the settings should be applied. Valid values are `Present` and `Absent`. Defaults to `Present`.

# Additional Information

This resource manages organization-level security and access settings in Azure DevOps. These settings affect the entire organization and should be managed carefully. Only one instance of this resource should be configured per organization.

# Examples

## Example 1: Configure organization security settings

``` PowerShell
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoOrganizationSettings 'ConfigureOrgSettings' {
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
```
