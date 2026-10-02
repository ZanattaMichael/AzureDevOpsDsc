# DSC AzDoReleaseFolderPermission Resource

## Syntax

```PowerShell
AzDoReleaseFolderPermission [string] #ResourceName
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
- **FolderPath**: The release folder path, for example `\Platform`. Omit to target the project's release root.
- **isInherited**: Whether the ACL inherits permissions from its parent. Defaults to `$true`.
- **Permissions**: The access control entries: `@{ Identity = '[ProjectName]\GroupName'; Permission = @{ ViewReleaseDefinition = 'Allow' } }`.
- **Ensure**: `Present` applies the permissions; `Absent` removes the folder's ACL so it falls back to inheriting.

## Additional Information

Release folders are secured by the **`ReleaseManagement`** namespace on the `vsrm.dev.azure.com` host. Release definitions beneath a folder inherit from it, which is how folder-level release permissions are normally administered.

Folder and release-definition names are ambiguous on the resource side, so folder paths carry their leading separator (`MyProject/\Platform`) to distinguish them from a definition of the same name; the API token drops it again.

`Ensure = 'Absent'` on the project release root is refused: it has no parent to inherit from.

Permission action names come from the namespace itself. Read them from `_apis/securitynamespaces/{namespaceId}` rather than assuming a fixed set.

## Examples

## Example 1: Sample Configuration using AzDoReleaseFolderPermission Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    Node localhost {
        AzDoReleaseFolderPermission PlatformFolderPermissions {
            ProjectName = 'MyProject'
            FolderPath  = '\Platform'
            isInherited = $true
            Permissions = @(
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
# Return the current configuration for AzDoReleaseFolderPermission
$properties = @{
    ProjectName = 'MyProject'
    FolderPath  = '\Platform'
    isInherited = $true
}

Invoke-DscResource -Name 'AzDoReleaseFolderPermission' -Method Get -Property $properties -ModuleName 'AzureDevOpsDscNative'
```
