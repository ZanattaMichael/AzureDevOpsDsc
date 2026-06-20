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

## Examples

## Example 1: Sample Configuration using AzDoProcess Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

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

Invoke-DscResource -Name 'AzDoProcess' -Method Get -Property $properties -ModuleName 'AzureDevOpsDsc'
```

## Example 3: Sample Configuration using AzDO-DSC-LCM

``` YAML
parameters: {}

variables: {
  ProcessName: Contoso Agile
}

resources:
- name: Contoso Agile Process
  type: AzureDevOpsDsc/AzDoProcess
  properties:
    ProcessName: $ProcessName
    ParentProcessName: Agile
    Description: Agile process customised for Contoso
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
