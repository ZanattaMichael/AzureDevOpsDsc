# DSC AzDoServicePrincipalEntitlement Resource

## Syntax

```PowerShell
AzDoServicePrincipalEntitlement [string] #ResourceName
{
    OriginId               = [String]$OriginId
    [ DisplayName          = [String]$DisplayName ]
    [ AccountLicenseType   = [String]$AccountLicenseType ]
    [ Ensure               = [String] {'Present', 'Absent'} ]
}
```

## Properties

### Common Properties

- **OriginId**: The Microsoft Entra object id of the service principal. This is the key property.
- **DisplayName**: A display name recorded with the entitlement. Informational — matching uses `OriginId`.
- **AccountLicenseType**: The access level to assign, for example `express` (Basic) or `stakeholder`.
- **Ensure**: Whether the service principal should be a member of the organization.

## Additional Information

Service principals and managed identities are organization members in their own right and need an access level, exactly as users do. `AzDoUserEntitlement` covers users only — these live on a separate endpoint.

The module can already *authenticate* as a service principal, a certificate-backed service principal, or a federated workload identity. This resource closes the matching gap on the managed side.

### Identity is matched by object id, not by name

Display names are neither unique nor stable, and renaming a service principal in Entra does not change its entitlement. Matching by name would make the resource believe the principal had vanished and create a duplicate, so `OriginId` is the key.

### Preview API

The service principal entitlements endpoint is a preview API. If an organization does not expose it, the lookup reports the entitlement as **absent** rather than failing, so one unavailable endpoint does not fail an entire configuration. That does mean a `Test()` in such an organization reports "not present" rather than an error — worth knowing when diagnosing a configuration that never converges.

### Removal cuts off access

`Ensure = 'Absent'` removes the service principal from the organization. Anything running as that identity — pipelines, federated deployments — loses access.

## Examples

## Example 1: Sample Configuration using AzDoServicePrincipalEntitlement Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    Node localhost {
        AzDoServicePrincipalEntitlement AddDeploymentIdentity {
            Ensure             = 'Present'
            OriginId           = '00000000-0000-0000-0000-000000000000'
            DisplayName        = 'contoso-deployment-sp'
            AccountLicenseType = 'express'
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoServicePrincipalEntitlement
$properties = @{
    OriginId = '00000000-0000-0000-0000-000000000000'
}

Invoke-DscResource -Name 'AzDoServicePrincipalEntitlement' -Method Get -Property $properties -ModuleName 'AzureDevOpsDscNative'
```

## Example 3: Sample Configuration using Dsc.PipelineRunner

``` YAML
parameters: {}

variables: {}

resources:
- name: Deployment Identity
  type: AzureDevOpsDscNative/AzDoServicePrincipalEntitlement
  properties:
    OriginId: 00000000-0000-0000-0000-000000000000
    DisplayName: contoso-deployment-sp
    AccountLicenseType: express
    Ensure: Present
```

Pipeline runner initialization:

``` PowerShell

Import-Module Dsc.PipelineRunner

$params = @{
    AzureDevopsOrganizationName = "SampleAzDoOrgName"
    exportConfigDir             = "C:\Datum\DSCOutput\"
    ConfigurationSourcePath     = 'https://configuration-path'
    JITToken                    = 'SampleJITToken'
    Mode                        = 'Set'
    AuthenticationType          = 'ManagedIdentity'
    ReportPath                  = 'C:\Datum\DSCOutput\Reports'
}

Invoke-DscPipelineRunner @params
```
