# DSC AzDoPipelineFolder Resource

## Syntax

```PowerShell
AzDoPipelineFolder [string] #ResourceName
{
    ProjectName            = [String]$ProjectName
    Path                   = [String]$Path
    [ Description          = [String]$Description ]
    [ AllowRecursiveDelete = [Boolean]$AllowRecursiveDelete ]
    [ Ensure               = [String] {'Present', 'Absent'} ]
}
```

## Properties

### Common Properties

- **ProjectName**: The name of the Azure DevOps project. Mandatory.
- **Path**: The full path of the folder, for example `\Platform\Release`. This is the key property.
- **Description**: An optional description shown in the Azure DevOps UI.
- **AllowRecursiveDelete**: Permits removal of a folder that still contains pipelines or sub-folders. Defaults to `$false`.
- **Ensure**: Specifies whether the folder should exist. Valid values are `Present` and `Absent`.

## Additional Information

Pipeline folder paths are **backslash-delimited** and rooted at `\` — unlike work item query paths, which use forward slashes. Forward slashes are accepted and normalized, so `\Platform\Release`, `Platform/Release` and `\Platform\Release\` all describe the same folder.

Unlike the work item query tree, the Build folders API creates missing ancestors implicitly, so a nested folder can be declared without declaring each level above it.

### Path is the key, and changing it does not move the folder

The Build folders API can rename or move a folder by supplying a different path, which takes every definition beneath it along. The resource deliberately does not use that: `Path` is the resource key, so a different path describes a *different* folder. A mistyped path therefore creates a new folder rather than silently relocating a whole tree.

### Deletion is recursive

Deleting a pipeline folder deletes every pipeline definition beneath it. Removal is refused unless `AllowRecursiveDelete` is `$true`.

The emptiness check consults both the folder listing (for sub-folders) and the definitions endpoint (for pipelines), because the folder listing does not report the definitions inside a folder. If that check cannot be completed — a transient API failure, for instance — the resource refuses to delete rather than treating "could not confirm" as "empty".

## Examples

## Example 1: Sample Configuration using AzDoPipelineFolder Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    Node localhost {
        AzDoPipelineFolder AddPlatformFolder {
            Ensure      = 'Present'
            ProjectName = 'MyProject'
            Path        = '\Platform'
            Description = 'Platform team pipelines'
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoPipelineFolder
$properties = @{
    ProjectName = 'MyProject'
    Path        = '\Platform'
}

Invoke-DscResource -Name 'AzDoPipelineFolder' -Method Get -Property $properties -ModuleName 'AzureDevOpsDscNative'
```

## Example 3: Sample Configuration using Dsc.PipelineRunner

``` YAML
parameters: {}

variables: {
  ProjectName: MyProject
}

resources:
- name: Platform Pipeline Folder
  type: AzureDevOpsDscNative/AzDoPipelineFolder
  dependsOn:
    - AzureDevOpsDscNative/AzDoProject/MyProject
  properties:
    ProjectName: $ProjectName
    Path: \Platform
    Description: Platform team pipelines
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
