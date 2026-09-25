# DSC AzDoReleaseDefinitionPermission Resource

## Syntax

```PowerShell
AzDoReleaseDefinitionPermission [string] #ResourceName
{
    ProjectName     = [String]$ProjectName
    DefinitionName  = [String]$DefinitionName
    [ FolderPath    = [String]$FolderPath ]
    [ isInherited   = [Boolean]$isInherited ]
    [ Permissions   = [HashTable[]]$Permissions ]
    [ Ensure        = [String] {'Present', 'Absent'} ]
}
```

## Properties

### Common Properties

- **ProjectName**: The name of the Azure DevOps project. This is the key property.
- **DefinitionName**: The name of the classic release definition. Mandatory.
- **FolderPath**: The release folder the definition lives in, for example `\Platform`. Omit for a definition at the release root.
- **isInherited**: Whether the ACL inherits permissions from its parent. Defaults to `$true`.
- **Permissions**: The access control entries: `@{ Identity = '[ProjectName]\GroupName'; Permission = @{ ViewReleaseDefinition = 'Allow' } }`.
- **Ensure**: `Present` applies the permissions; `Absent` removes the definition's ACL so it falls back to inheriting.

## Additional Information

Release definitions are secured by the **`ReleaseManagement`** namespace on the `vsrm.dev.azure.com` host, the same namespace as release folders.

Because no resource yet caches the full set of release definitions, this resource resolves `DefinitionName` (and, when given, `FolderPath`) directly against the `release/definitions` list endpoint with `isExactNameMatch=true`, and caches the match under `LiveReleaseDefinitions` for reuse within the same run.

A release definition always has a parent (its folder, or the release root) to inherit from, so unlike `AzDoReleaseFolderPermission` there is no root-targeting restriction here.

Permission action names come from the namespace itself. Read them from `_apis/securitynamespaces/{namespaceId}` rather than assuming a fixed set.

## Examples

## Example 1: Sample Configuration using AzDoReleaseDefinitionPermission Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    Node localhost {
        AzDoReleaseDefinitionPermission PlatformReleaseDefinitionPermissions {
            ProjectName    = 'MyProject'
            DefinitionName = 'Platform Release'
            FolderPath     = '\Platform'
            isInherited    = $true
            Permissions    = @(
                @{
                    Identity   = '[MyProject]\Platform Team'
                    Permission = @{ ViewReleaseDefinition = 'Allow'; ManageReleaseApprovers = 'Allow' }
                }
            )
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoReleaseDefinitionPermission
$properties = @{
    ProjectName    = 'MyProject'
    DefinitionName = 'Platform Release'
    FolderPath     = '\Platform'
    isInherited    = $true
}

Invoke-DscResource -Name 'AzDoReleaseDefinitionPermission' -Method Get -Property $properties -ModuleName 'AzureDevOpsDscNative'
```
