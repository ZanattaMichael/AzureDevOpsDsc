# DSC AzDoGroupEntitlement Resource

## Syntax

```PowerShell
AzDoGroupEntitlement [string] #ResourceName
{
    GroupDisplayName       = [String]$GroupDisplayName
    [ AccountLicenseType   = [String]$AccountLicenseType ]
    [ GroupOrigin          = [String] {'aad', 'vsts'} ]
    [ GroupOriginId        = [String]$GroupOriginId ]
    [ Ensure               = [String] {'Present', 'Absent'} ]
}
```

## Properties

### Common Properties

- **GroupDisplayName**: The display name or principal name of the group. This is the key property.
- **AccountLicenseType**: The access level the rule assigns — for example `express` (Basic), `stakeholder` or `advanced`.
- **GroupOrigin**: `aad` for a Microsoft Entra group, `vsts` for an Azure DevOps group. Defaults to `aad`.
- **GroupOriginId**: The Entra object id of the group. Supplying it makes creation unambiguous when several groups share a display name.
- **Ensure**: Whether the licensing rule should exist.

## Additional Information

A group entitlement is a **licensing rule**: it assigns an access level to every member of a group. This is how licensing is administered at scale — `AzDoUserEntitlement` assigns a level to a single user, which does not scale to an organization.

### Changing the level re-licenses the group

Because the rule applies to members, changing `AccountLicenseType` changes what everyone in the group gets. Lowering a rule from `express` to `stakeholder` takes Basic access away from every member who has no other rule or direct assignment granting it.

### Removing the rule does not remove members

`Ensure = 'Absent'` deletes the rule, not the people. Members keep any license held directly or granted by another rule, and lose only what this rule gave them.

## Examples

## Example 1: Sample Configuration using AzDoGroupEntitlement Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    Node localhost {
        AzDoGroupEntitlement LicenseDevelopers {
            Ensure             = 'Present'
            GroupDisplayName   = 'Contoso Developers'
            AccountLicenseType = 'express'
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoGroupEntitlement
$properties = @{
    GroupDisplayName = 'Contoso Developers'
}

Invoke-DscResource -Name 'AzDoGroupEntitlement' -Method Get -Property $properties -ModuleName 'AzureDevOpsDscNative'
```

## Example 3: Sample Configuration using Dsc.PipelineRunner

``` YAML
parameters: {}

variables: {}

resources:
- name: Developer Licensing
  type: AzureDevOpsDscNative/AzDoGroupEntitlement
  properties:
    GroupDisplayName: Contoso Developers
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
