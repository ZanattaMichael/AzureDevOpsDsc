# DSC AzDoPicklist Resource

## Syntax

```PowerShell
AzDoPicklist [string] #ResourceName
{
    PicklistName     = [String]$PicklistName
    [ Items          = [String[]]$Items ]
    [ PicklistType   = [String] {'String', 'Integer'} ]
    [ IsSuggested    = [Boolean]$IsSuggested ]
    [ Ensure         = [String] {'Present', 'Absent'} ]
}
```

## Properties

### Common Properties

- **PicklistName**: The name of the picklist. This is the key property.
- **Items**: The complete set of allowed values, in the order they should appear.
- **PicklistType**: `String` or `Integer`. Defaults to `String`.
- **IsSuggested**: When true the list is a suggestion rather than a closed set, and users may enter values not on it.
- **Ensure**: Whether the picklist should exist.

## Additional Information

A picklist holds the allowed values behind a custom field of type "picklist". It is the first thing to declare when building out process customization, since a field of that type needs a list to point at.

### Organization-scoped, not process-scoped

One picklist can back fields in several processes. Changing it changes every field that uses it — this is not a per-process setting.

### Items are replaced wholesale

The update endpoint takes the complete list, so any value omitted from `Items` is removed. **Removing a value does not rewrite work items that already carry it.** They keep the value, and it then fails validation the next time somebody edits them. Narrowing a picklist is worth doing deliberately rather than as a side effect of tidying a configuration.

Order is significant and compared as an ordered sequence, because it is the order shown in the picker.

### The type is fixed at creation

`PicklistType` cannot be changed after the list exists. A configuration asking for a different type is reported as an error rather than silently recreating the list, which would drop every value already stored in the fields backed by it.

A picklist that still backs a field cannot be deleted — the API rejects it rather than orphaning the field.

## Examples

## Example 1: Sample Configuration using AzDoPicklist Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    Node localhost {
        AzDoPicklist Severity {
            Ensure       = 'Present'
            PicklistName = 'Severity'
            Items        = @('1 - Critical', '2 - High', '3 - Medium', '4 - Low')
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoPicklist
$properties = @{
    PicklistName = 'Severity'
}

Invoke-DscResource -Name 'AzDoPicklist' -Method Get -Property $properties -ModuleName 'AzureDevOpsDscNative'
```

## Example 3: Sample Configuration using Dsc.PipelineRunner

``` YAML
parameters: {}

variables: {}

resources:
- name: Severity Picklist
  type: AzureDevOpsDscNative/AzDoPicklist
  properties:
    PicklistName: Severity
    Items:
      - 1 - Critical
      - 2 - High
      - 3 - Medium
      - 4 - Low
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
