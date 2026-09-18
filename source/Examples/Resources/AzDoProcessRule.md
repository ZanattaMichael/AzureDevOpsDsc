# DSC AzDoProcessRule Resource

## Syntax

```PowerShell
AzDoProcessRule [string] #ResourceName
{
    ProcessName          = [String]$ProcessName
    WorkItemTypeName     = [String]$WorkItemTypeName
    RuleName             = [String]$RuleName
    [ Conditions         = [HashTable[]]$Conditions ]
    [ Actions            = [HashTable[]]$Actions ]
    [ IsDisabled         = [Boolean]$IsDisabled ]
    [ Ensure             = [String] {'Present', 'Absent'} ]
}
```

## Properties

### Common Properties

- **ProcessName**: The name of the inherited process. Mandatory.
- **WorkItemTypeName**: The display name of the work item type. Mandatory.
- **RuleName**: The name of the rule. This is the key property.
- **Conditions**: The conditions under which the rule applies.
- **Actions**: The actions the rule performs.
- **IsDisabled**: Whether the rule is disabled. This is the only way to switch off an inherited rule.
- **Ensure**: Whether the rule should exist.

## Additional Information

### Conditions and actions are passed through, not abstracted

They are written as the API models them:

``` PowerShell
Conditions = @( @{ conditionType = 'when'; field = 'System.State'; value = 'Active' } )
Actions    = @( @{ actionType = 'makeRequired'; targetField = 'Custom.Severity' } )
```

This is deliberate. The condition and action vocabulary is large and grows between API versions; a friendlier wrapper would need revising every time Azure DevOps adds an action type, and would silently fail to support the ones it did not know about.

### Drift detection normalizes both sides

A configuration supplies hashtables and the API returns objects, and the API also fills in keys the configuration omitted — an action written without a `value` comes back with an explicit null one. Comparing them raw would report drift on every `Test()`. Both sides are reduced to a canonical form first; keys are compared case-insensitively (the API is inconsistent between versions) while values are left alone, since a field reference name's case is the user's intent.

Conditions and actions are compared as **ordered sequences**, because order is significant within a rule.

### Updates replace the whole rule

The API takes the complete rule, so the conditions and actions in the configuration are the whole set. Where the configuration does not state them at all, the live values are sent back unchanged — so toggling `IsDisabled` does not wipe a rule's logic.

### Inherited rules cannot be deleted

Only custom rules can be removed. `IsDisabled = $true` is the supported way to switch off a rule inherited from the parent process, and the removal error says so.

## Examples

## Example 1: Sample Configuration using AzDoProcessRule Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    Node localhost {
        AzDoProcessRule SeverityRequiredWhenActive {
            Ensure           = 'Present'
            ProcessName      = 'Contoso Agile'
            WorkItemTypeName = 'Incident'
            RuleName         = 'Severity required when active'
            Conditions       = @( @{ conditionType = 'when'; field = 'System.State'; value = 'Active' } )
            Actions          = @( @{ actionType = 'makeRequired'; targetField = 'Custom.Severity' } )
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoProcessRule
$properties = @{
    ProcessName      = 'Contoso Agile'
    WorkItemTypeName = 'Incident'
    RuleName         = 'Severity required when active'
}

Invoke-DscResource -Name 'AzDoProcessRule' -Method Get -Property $properties -ModuleName 'AzureDevOpsDscNative'
```

## Example 3: Sample Configuration using Dsc.PipelineRunner

``` YAML
parameters: {}

variables: {}

resources:
- name: Severity Required Rule
  type: AzureDevOpsDscNative/AzDoProcessRule
  dependsOn:
    - AzureDevOpsDscNative/AzDoProcessField/Incident Severity Field
  properties:
    ProcessName: Contoso Agile
    WorkItemTypeName: Incident
    RuleName: Severity required when active
    Conditions:
      - conditionType: when
        field: System.State
        value: Active
    Actions:
      - actionType: makeRequired
        targetField: Custom.Severity
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
