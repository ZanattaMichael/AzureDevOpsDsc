# DSC AzDoWIPTags Resource

## Syntax

```PowerShell
AzDoWIPTags [string] #ResourceName
{
    ProjectName                 = [String]$ProjectName
    WorkItemTrackingTagList     = [String[]]$WorkItemTrackingTagList
}
```

## Properties

### Common Properties

- **ProjectName**: The name of the Azure DevOps project. This property is mandatory and serves as a key property for the resource.
- **WorkItemTrackingTagList**: An array of work item tracking tags to manage within the project.

## Additional Information

This resource manages the work item tag vocabulary in an Azure DevOps project — the tags that exist and are available to apply to work items.

### It does not police the tags that appear beside the vocabulary

`AzDoWIPTags` ensures the tags you declare exist. It does nothing about the ones that accumulate next to them — `Bugfix` beside `Bug`, `frontend` beside `Frontend`, `Tech-Debt` beside `Tech Debt`. Those arrive from people typing tags directly on work items and will not show up as drift here.

[AzDoWIPTagHygiene](AzDoWIPTagHygiene.md) is the companion that finds them and merges them into the canonical vocabulary. It defaults to reporting rather than changing, so it is safe to declare alongside this resource and read the warnings before enabling merges.

### Tag creation is a side effect

Azure DevOps has no API for creating a tag directly. Tags exist only once something is tagged, so this resource creates them by adding a temporary work item carrying the tags and then deleting it — the tags persist project-wide. The `/wit/tags` collection is also eventually consistent, so creation waits for the new tags to become listable before returning; without that, a `Set` could be followed immediately by a `Test` reading a stale list.

## Examples

## Example 1: Sample Configuration using AzDoWIPTags Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    Node localhost {
        AzDoWIPTags AddWIPTags {
            ProjectName             = 'MyProject'
            WorkItemTrackingTagList = @('Bug', 'Feature', 'Improvement')
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoWIPTags
$properties = @{
    ProjectName             = 'MyProject'
    WorkItemTrackingTagList = @('Bug', 'Feature', 'Improvement')
}

Invoke-DscResource -Name 'AzDoWIPTags' -Method Get -Property $properties -ModuleName 'AzureDevOpsDscNative'
```

## Example 3: Sample Configuration using Dsc.PipelineRunner

``` YAML
parameters: {}

variables: {
  ProjectName: MyProject
}

resources:
- name: Work Item Tags
  type: AzureDevOpsDscNative/AzDoWIPTags
  dependsOn:
    - AzureDevOpsDscNative/AzDoProject/MyProject
  properties:
    ProjectName: $ProjectName
    WorkItemTrackingTagList:
      - Bug
      - Feature
      - Improvement
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
