# DSC AzDoProcess Resource

## Syntax

```PowerShell
AzDoProcess [string] #ResourceName
{
    ProcessName         = [String]$ProcessName
    ParentProcessName   = [String]$ParentProcessName
    [ Description       = [String]$Description ]
    [ Ensure           = [String] {'Present', 'Absent'} ]
}
```

## Properties

### Common Properties

- **ProcessName**: The name of the inherited process. This property is mandatory and serves as the key property for the resource.
- **ParentProcessName**: The name of the parent (system or custom) process to inherit from, for example `Agile`, `Scrum`, `CMMI` or `Basic`. This property is mandatory. It is immutable — the parent cannot be changed after creation.
- **Description**: An optional description for the process.
- **Ensure**: Specifies whether the process should exist. Valid values are `Present` and `Absent`.

## Additional Information

This resource creates and manages Azure DevOps **inherited processes** (process templates) via the Work Item Tracking Process REST API. Only the description is reconciled after creation; the parent process is fixed. A process that is in use by a project (or a system process) cannot be deleted.

### This resource is the container, not the customization

`AzDoProcess` creates the process. What makes an inherited process useful — custom work item types, fields, states, rules and backlogs — is managed by a family of companion resources, all of which take this process's name and should `DependsOn` it:

| Resource | Manages |
|---|---|
| [AzDoPicklist](AzDoPicklist.md) | The allowed values behind picklist-typed fields (organization-scoped) |
| [AzDoProcessWorkItemType](AzDoProcessWorkItemType.md) | Custom and inherited work item types |
| [AzDoProcessField](AzDoProcessField.md) | Fields on a work item type, and their required/default/read-only settings |
| [AzDoProcessState](AzDoProcessState.md) | Custom workflow states |
| [AzDoProcessRule](AzDoProcessRule.md) | Conditional rules |
| [AzDoProcessBehavior](AzDoProcessBehavior.md) | Which backlog a work item type appears on |

Two things catch people out. **Only inherited processes can be customized** — the system processes (Agile, Scrum, Basic, CMMI) are read-only, which is why this resource exists at all. And a custom work item type **appears on no backlog and no board** until `AzDoProcessBehavior` associates it with one; creating the type and stopping there leaves it invisible.

Form layout (pages, groups and controls) is not yet managed by this module — see [`docs/ResourceRoadmap.md`](../../../docs/ResourceRoadmap.md).

## Examples

## Example 1: Sample Configuration using AzDoProcess Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    Node localhost {
        AzDoProcess ContosoAgile {
            Ensure            = 'Present'
            ProcessName       = 'Contoso Agile'
            ParentProcessName = 'Agile'
            Description       = 'Agile process customised for Contoso'
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoProcess
$properties = @{
    ProcessName       = 'Contoso Agile'
    ParentProcessName = 'Agile'
}

Invoke-DscResource -Name 'AzDoProcess' -Method Get -Property $properties -ModuleName 'AzureDevOpsDscNative'
```

## Example 3: Sample Configuration using Dsc.PipelineRunner

``` YAML
parameters: {}

variables: {
  ProcessName: Contoso Agile
}

resources:
- name: Contoso Agile Process
  type: AzureDevOpsDscNative/AzDoProcess
  properties:
    ProcessName: $ProcessName
    ParentProcessName: Agile
    Description: Agile process customised for Contoso
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
