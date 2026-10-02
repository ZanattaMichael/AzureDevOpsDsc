# DSC AzDoProcessState Resource

## Syntax

```PowerShell
AzDoProcessState [string] #ResourceName
{
    ProcessName          = [String]$ProcessName
    WorkItemTypeName     = [String]$WorkItemTypeName
    StateName            = [String]$StateName
    [ StateCategory      = [String] {'Proposed','InProgress','Resolved','Completed','Removed'} ]
    [ Color              = [String]$Color ]
    [ Order              = [Int32]$Order ]
    [ Ensure             = [String] {'Present', 'Absent'} ]
}
```

## Properties

### Common Properties

- **ProcessName**: The name of the inherited process. Mandatory.
- **WorkItemTypeName**: The display name of the work item type. Mandatory.
- **StateName**: The name of the state. This is the key property.
- **StateCategory**: `Proposed`, `InProgress`, `Resolved`, `Completed` or `Removed`.
- **Color**: The hex colour, with or without a leading `#`.
- **Order**: The position of the state within its category.
- **Ensure**: Whether the state should exist on the work item type.

## Additional Information

### The category matters more than the name

Boards, cumulative flow diagrams and the Analytics service all reason about **state categories**, not state names. A state in the wrong category looks right in the work item form and is wrong in every metric — an `InProgress` state that should be `Completed` will keep items showing as unfinished on every chart.

### The category cannot be changed after creation

The API refuses, because moving a state between categories would reclassify every work item currently in it. A configuration asking for a different category is reported as an **error**, not as drift — recreating the state to force the change would strand those work items. To move a state between categories, create a new state in the target category and migrate the work items to it.

### Removal

Only **custom** states can be deleted; an inherited state belongs to the parent process's workflow and the resource reports that rather than letting the API fail.

Work items sitting in a deleted state are **not moved**. They keep the value, which then fails validation the next time somebody edits them, so removing a state that is in use is worth doing deliberately.

## Examples

## Example 1: Sample Configuration using AzDoProcessState Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    Node localhost {
        AzDoProcessState Triaged {
            Ensure           = 'Present'
            ProcessName      = 'Contoso Agile'
            WorkItemTypeName = 'Incident'
            StateName        = 'Triaged'
            StateCategory    = 'InProgress'
            Color            = '007ACC'
            Order            = 2
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoProcessState
$properties = @{
    ProcessName      = 'Contoso Agile'
    WorkItemTypeName = 'Incident'
    StateName        = 'Triaged'
}

Invoke-DscResource -Name 'AzDoProcessState' -Method Get -Property $properties -ModuleName 'AzureDevOpsDscNative'
```

## Example 3: Sample Configuration using Dsc.PipelineRunner

``` YAML
parameters: {}

variables: {}

resources:
- name: Triaged State
  type: AzureDevOpsDscNative/AzDoProcessState
  dependsOn:
    - AzureDevOpsDscNative/AzDoProcessWorkItemType/Incident Work Item Type
  properties:
    ProcessName: Contoso Agile
    WorkItemTypeName: Incident
    StateName: Triaged
    StateCategory: InProgress
    Color: 007ACC
    Order: 2
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
