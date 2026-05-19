# DSC AzDoOrganizationSettings Resource

## Syntax

```PowerShell
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

## Properties

### Common Properties

- **OrganizationName**: The name of the Azure DevOps organization. This property is mandatory and serves as the key property for the resource. It is not configurable after initial setup.
- **AllowPublicProjects**: Whether users can create public (anonymous-access) projects.
- **AllowExternalGuestAccess**: Whether external guest users (Azure AD guests) can be added to the organization.
- **EnableOAuthAuthentication**: Whether OAuth authentication is enabled for third-party applications.
- **EnableSSHAuthentication**: Whether SSH authentication is enabled for Git operations.
- **DisallowAadGuestUserPolicy**: Whether the Azure AD guest user policy is disallowed.
- **Ensure**: Specifies whether the settings should be applied. Valid values are `Present` and `Absent`.

## Additional Information

This resource manages organization-level security and access settings in Azure DevOps. These settings affect the entire organization and should be managed carefully. Only one instance of this resource should be configured per organization.

## Examples

## Example 1: Sample Configuration using AzDoOrganizationSettings Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoOrganizationSettings ConfigureOrgSettings {
            Ensure                     = 'Present'
            OrganizationName           = 'SampleAzDoOrgName'
            AllowPublicProjects        = $false
            AllowExternalGuestAccess   = $false
            EnableOAuthAuthentication  = $true
            EnableSSHAuthentication    = $true
            DisallowAadGuestUserPolicy = $false
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoOrganizationSettings
$properties = @{
    OrganizationName = 'SampleAzDoOrgName'
}

Invoke-DscResource -Name 'AzDoOrganizationSettings' -Method Get -Property $properties -ModuleName 'AzureDevOpsDsc'
```

## Example 3: Sample Configuration using AzDO-DSC-LCM

``` YAML
parameters: {}

variables: {
  OrganizationName: SampleAzDoOrgName
}

resources:
- name: Organization Security Settings
  type: AzureDevOpsDsc/AzDoOrganizationSettings
  properties:
    OrganizationName: $OrganizationName
    AllowPublicProjects: false
    AllowExternalGuestAccess: false
    EnableOAuthAuthentication: true
    EnableSSHAuthentication: true
    DisallowAadGuestUserPolicy: false
    Ensure: Present
```

LCM Initialization:

``` PowerShell

$params = @{
    AzureDevopsOrganizationName = "SampleAzDoOrgName"
    ConfigurationDirectory      = "C:\Datum\DSCOutput\"
    ConfigurationUrl            = 'https://configuration-path'
    JITToken                    = 'SampleJITToken'
    Mode                        = 'Set'
    AuthenticationType          = 'ManagedIdentity'
    ReportPath                  = 'C:\Datum\DSCOutput\Reports'
}

Invoke-AzDoLCM @params
```
