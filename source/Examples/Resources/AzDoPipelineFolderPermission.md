# DSC AzDoPipelineFolderPermission Resource

## Syntax

```PowerShell
AzDoPipelineFolderPermission [string] #ResourceName
{
    ProjectName     = [String]$ProjectName
    [ FolderPath    = [String]$FolderPath ]
    [ isInherited   = [Boolean]$isInherited ]
    [ Permissions   = [HashTable[]]$Permissions ]
    [ Ensure        = [String] {'Present', 'Absent'} ]
}
```

## Properties

### Common Properties

- **ProjectName**: The name of the Azure DevOps project. This is the key property.
- **FolderPath**: The pipeline folder path, for example `\Platform`. Omit to target the project's build root.
- **isInherited**: Whether the ACL inherits permissions from its parent. Defaults to `$true`.
- **Permissions**: The access control entries: `@{ Identity = '[ProjectName]\GroupName'; Permission = @{ ViewBuilds = 'Allow' } }`.
- **Ensure**: `Present` applies the permissions; `Absent` removes the folder's ACL so it falls back to inheriting.

## Additional Information

Pipeline folders are secured by the **`Build`** namespace, the same namespace that secures pipeline definitions. Definitions beneath a folder inherit from it, which is how pipeline permissions are normally administered.

### This closed a gap in the module

Before this resource existed, the `Build` branch of the ACL layer understood only the *definition* token form (`{projectId}/{definitionId}`). A folder's token addresses the folder by path (`{projectId}/{folderPath}`), so folder-level pipeline permissions could not be expressed at all — including through `AzDoPipelinePermission`.

### Folder and pipeline names are ambiguous, so folder paths carry a marker

A pipeline can legitimately be named `Platform`, and so can a folder. On the resource side the token `MyProject/Platform` is therefore ambiguous. Folder paths are written with their leading separator (`MyProject/\Platform`) so the two can be told apart; the API token drops it again.

`Ensure = 'Absent'` on the project build root is refused: it has no parent to inherit from.

Permission action names come from the namespace itself. Read them from `_apis/securitynamespaces/{namespaceId}` rather than assuming a fixed set.

## Examples

## Example 1: Sample Configuration using AzDoPipelineFolderPermission Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    Node localhost {
        AzDoPipelineFolderPermission PlatformFolderPermissions {
            ProjectName = 'MyProject'
            FolderPath  = '\Platform'
            isInherited = $true
            Permissions = @(
                @{
                    Identity   = '[MyProject]\Platform Team'
                    Permission = @{ ViewBuilds = 'Allow'; QueueBuilds = 'Allow' }
                }
            )
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoPipelineFolderPermission
$properties = @{
    ProjectName = 'MyProject'
    FolderPath  = '\Platform'
    isInherited = $true
}

Invoke-DscResource -Name 'AzDoPipelineFolderPermission' -Method Get -Property $properties -ModuleName 'AzureDevOpsDscNative'
```

## Example 3: Sample Configuration using Dsc.PipelineRunner

``` YAML
parameters: {}

variables: {
  ProjectName: MyProject
}

resources:
- name: Platform Folder Permissions
  type: AzureDevOpsDscNative/AzDoPipelineFolderPermission
  dependsOn:
    - AzureDevOpsDscNative/AzDoPipelineFolder/Platform Pipeline Folder
  properties:
    ProjectName: $ProjectName
    FolderPath: \Platform
    isInherited: true
    Permissions:
      - Identity: '[MyProject]\Platform Team'
        Permission:
          ViewBuilds: Allow
          QueueBuilds: Allow
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
