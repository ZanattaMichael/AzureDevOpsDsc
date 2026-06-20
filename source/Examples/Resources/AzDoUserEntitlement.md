# DSC AzDoUserEntitlement Resource

## Syntax

```PowerShell
AzDoUserEntitlement [string] #ResourceName
{
    UserPrincipalName    = [String]$UserPrincipalName
    AccountLicenseType   = [String] {'stakeholder', 'express', 'advanced', 'professional', 'earlyAdopter', 'none'}
    [ Ensure            = [String] {'Present', 'Absent'} ]
}
```

## Properties

### Common Properties

- **UserPrincipalName**: The user's principal name (email / UPN). This property is mandatory and serves as the key property for the resource.
- **AccountLicenseType**: The access level (license) to assign. Valid values are `stakeholder`, `express` (Basic), `advanced` (Basic + Test Plans), `professional`, `earlyAdopter` and `none`.
- **Ensure**: Specifies whether the user should be a member of the organization. Valid values are `Present` and `Absent`. Removing a user unassigns their license/extensions and removes them from all project memberships.

## Additional Information

This resource adds and removes organization users and manages their access level via the Member Entitlement Management API. The user must be a resolvable identity in the backing directory (e.g. Microsoft Entra ID) to be added. Adding a user consumes a license of the specified type.

## Examples

## Example 1: Sample Configuration using AzDoUserEntitlement Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoUserEntitlement JaneBasic {
            Ensure             = 'Present'
            UserPrincipalName  = 'jane@contoso.com'
            AccountLicenseType = 'express'
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoUserEntitlement
$properties = @{
    UserPrincipalName  = 'jane@contoso.com'
    AccountLicenseType = 'express'
}

Invoke-DscResource -Name 'AzDoUserEntitlement' -Method Get -Property $properties -ModuleName 'AzureDevOpsDsc'
```

## Example 3: Sample Configuration using AzDO-DSC-LCM

``` YAML
parameters: {}

variables: {}

resources:
- name: Add Jane as a Basic user
  type: AzureDevOpsDsc/AzDoUserEntitlement
  properties:
    UserPrincipalName: jane@contoso.com
    AccountLicenseType: express
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
