# DSC AzDoQueryFolder Resource

## Syntax

```PowerShell
AzDoQueryFolder [string] #ResourceName
{
    ProjectName            = [String]$ProjectName
    Path                   = [String]$Path
    [ AllowRecursiveDelete = [Boolean]$AllowRecursiveDelete ]
    [ Ensure               = [String] {'Present', 'Absent'} ]
}
```

## Properties

### Common Properties

- **ProjectName**: The name of the Azure DevOps project. Mandatory.
- **Path**: The full path of the folder, including the root - for example `Shared Queries/Platform/Release`. This is the key property. Backslashes are accepted and normalized, so `Shared Queries\Platform`, `/Shared Queries/Platform/` and `Shared Queries//Platform` all describe the same folder.
- **AllowRecursiveDelete**: Permits removal of a folder that still contains queries or sub-folders. Defaults to `$false`.
- **Ensure**: Specifies whether the folder should exist. Valid values are `Present` and `Absent`.

## Additional Information

Query folders are configuration in their own right rather than a naming convention: they carry ACLs, and a query cannot be created at a path whose folders do not exist.

Each level of the tree is its own resource. The resource deliberately does not create its own ancestry - if it did, two folders sharing a parent would race to create it and `Test()` results would depend on apply order. Declare each level and chain them with `DependsOn`.

Only the `Shared Queries` tree is manageable. `My Queries` is per-user and has no meaningful desired state for a machine-level configuration.

Deleting a query folder in Azure DevOps deletes its entire subtree. Removal of a folder that still has children is therefore refused unless `AllowRecursiveDelete` is set to `$true`, so that narrowing a configuration cannot quietly delete other people's saved queries.

A query already occupying the folder's path is reported as an error rather than resolved automatically, since the only way to resolve it would be to delete that query.

## Examples

## Example 1: Sample Configuration using AzDoQueryFolder Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    Node localhost {
        AzDoQueryFolder AddPlatformFolder {
            Ensure      = 'Present'
            ProjectName = 'MyProject'
            Path        = 'Shared Queries/Platform'
        }

        AzDoQueryFolder AddReleaseFolder {
            Ensure      = 'Present'
            ProjectName = 'MyProject'
            Path        = 'Shared Queries/Platform/Release'
            DependsOn   = '[AzDoQueryFolder]AddPlatformFolder'
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoQueryFolder
$properties = @{
    ProjectName = 'MyProject'
    Path        = 'Shared Queries/Platform'
}

Invoke-DscResource -Name 'AzDoQueryFolder' -Method Get -Property $properties -ModuleName 'AzureDevOpsDscNative'
```

## Example 3: Sample Configuration using Dsc.PipelineRunner

``` YAML
parameters: {}

variables: {
  ProjectName: MyProject
}

resources:
- name: Platform Query Folder
  type: AzureDevOpsDscNative/AzDoQueryFolder
  dependsOn:
    - AzureDevOpsDscNative/AzDoProject/MyProject
  properties:
    ProjectName: $ProjectName
    Path: Shared Queries/Platform
    Ensure: Present

- name: Release Query Folder
  type: AzureDevOpsDscNative/AzDoQueryFolder
  dependsOn:
    - AzureDevOpsDscNative/AzDoQueryFolder/Platform Query Folder
  properties:
    ProjectName: $ProjectName
    Path: Shared Queries/Platform/Release
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
