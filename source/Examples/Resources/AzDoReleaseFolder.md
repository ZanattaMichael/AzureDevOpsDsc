# DSC AzDoReleaseFolder Resource

## Syntax

```PowerShell
AzDoReleaseFolder [string] #ResourceName
{
    ProjectName            = [String]$ProjectName
    Path                   = [String]$Path
    [ Description          = [String]$Description ]
    [ AllowRecursiveDelete = [Boolean]$AllowRecursiveDelete ]
    [ Ensure                = [String] {'Present', 'Absent'} ]
}
```

## Properties

### Common Properties

- **ProjectName**: The name of the Azure DevOps project. Mandatory.
- **Path**: The full path of the release folder, for example `\Platform`. This is the key property.
- **Description**: An optional description shown in the Azure DevOps UI.
- **AllowRecursiveDelete**: Permits removal of a folder that still contains sub-folders or release definitions. Defaults to `$false`.
- **Ensure**: Specifies whether the folder should exist. Valid values are `Present` and `Absent`.

## Additional Information

Classic Release Management folders live on the `vsrm.dev.azure.com` host rather than `dev.azure.com`, but the folder path convention is otherwise identical to pipeline folders: **backslash-delimited** and rooted at `\`. Forward slashes are accepted and normalized, so `\Platform`, `Platform` and `\Platform\` all describe the same folder.

The project release root itself cannot be managed as a folder — there is nothing to create or remove there.

### Deletion is recursive

Deleting a release folder deletes every sub-folder and release definition beneath it. Removal is refused unless `AllowRecursiveDelete` is `$true`. The emptiness check consults both the folder listing (for sub-folders) and the definitions endpoint (for release definitions), because the folder listing does not report the definitions inside a folder. If that check cannot be completed, the resource refuses to delete rather than treating "could not confirm" as "empty".

### Classic creation may be disabled

Some organizations disable classic Release Management creation entirely. When that setting is on, `New-AzDoReleaseFolder` throws a message naming the setting rather than surfacing the raw API error.

## Examples

## Example 1: Sample Configuration using AzDoReleaseFolder Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    Node localhost {
        AzDoReleaseFolder AddPlatformReleaseFolder {
            Ensure      = 'Present'
            ProjectName = 'MyProject'
            Path        = '\Platform'
            Description = 'Platform team releases'
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoReleaseFolder
$properties = @{
    ProjectName = 'MyProject'
    Path        = '\Platform'
}

Invoke-DscResource -Name 'AzDoReleaseFolder' -Method Get -Property $properties -ModuleName 'AzureDevOpsDscNative'
```
