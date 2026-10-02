# DSC AzDoProcessBehavior Resource

## Syntax

```PowerShell
AzDoProcessBehavior [string] #ResourceName
{
    ProcessName          = [String]$ProcessName
    WorkItemTypeName     = [String]$WorkItemTypeName
    BehaviorName         = [String]$BehaviorName
    [ IsDefault          = [Boolean]$IsDefault ]
    [ Ensure             = [String] {'Present', 'Absent'} ]
}
```

## Properties

### Common Properties

- **ProcessName**: The name of the inherited process. Mandatory.
- **WorkItemTypeName**: The display name of the work item type. Mandatory.
- **BehaviorName**: The name or reference name of the behavior, for example `Stories` or `System.RequirementBacklogBehavior`. This is the key property.
- **IsDefault**: Whether this work item type is the default for creating new items at that backlog level.
- **Ensure**: Whether the association should exist.

## Additional Information

### This is usually the missing step

When a newly created custom work item type appears to do nothing, this is almost always why. The type exists, but until it is associated with a **behavior** it shows up on no backlog and no board. Creating a type with `AzDoProcessWorkItemType` and stopping there leaves it invisible to the people meant to use it.

Behaviors are the backlog levels a process exposes — Epics, Features, Stories, Tasks. They are **process-scoped**, while the association managed here is **per work item type**.

Behaviors are matched by display name or reference name, since a configuration is naturally written with the readable name (`Stories`) while the API addresses them by reference name (`System.RequirementBacklogBehavior`).

A `BehaviorName` that does not exist on the process is reported as an **error** rather than as a missing association, because creating it would fail — that is a configuration mistake, not drift.

### Removal is reversible

Removing an association takes the work item type off that backlog. The type and its work items are untouched, so re-adding the association restores it.

## Examples

## Example 1: Sample Configuration using AzDoProcessBehavior Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    Node localhost {
        AzDoProcessWorkItemType Incident {
            Ensure           = 'Present'
            ProcessName      = 'Contoso Agile'
            WorkItemTypeName = 'Incident'
        }

        AzDoProcessBehavior IncidentOnRequirements {
            Ensure           = 'Present'
            ProcessName      = 'Contoso Agile'
            WorkItemTypeName = 'Incident'
            BehaviorName     = 'Stories'
            DependsOn        = '[AzDoProcessWorkItemType]Incident'
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoProcessBehavior
$properties = @{
    ProcessName      = 'Contoso Agile'
    WorkItemTypeName = 'Incident'
    BehaviorName     = 'Stories'
}

Invoke-DscResource -Name 'AzDoProcessBehavior' -Method Get -Property $properties -ModuleName 'AzureDevOpsDscNative'
```

## Example 3: Sample Configuration using Dsc.PipelineRunner

``` YAML
parameters: {}

variables: {}

resources:
- name: Incident On Requirements Backlog
  type: AzureDevOpsDscNative/AzDoProcessBehavior
  dependsOn:
    - AzureDevOpsDscNative/AzDoProcessWorkItemType/Incident Work Item Type
  properties:
    ProcessName: Contoso Agile
    WorkItemTypeName: Incident
    BehaviorName: Stories
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
