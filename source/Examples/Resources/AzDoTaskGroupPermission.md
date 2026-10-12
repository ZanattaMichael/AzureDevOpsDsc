# DSC AzDoTaskGroupPermission Resource

## Syntax

```PowerShell
AzDoTaskGroupPermission [string] #ResourceName
{
    ProjectName     = [String]$ProjectName
    [ TaskGroupName = [String]$TaskGroupName ]
    [ isInherited   = [Boolean]$isInherited ]
    [ Permissions   = [HashTable[]]$Permissions ]
    [ Ensure        = [String] {'Present', 'Absent'} ]
}
```

## Permissions Syntax

``` PowerShell
AzDoTaskGroupPermission/Permissions
{
    Identity   = [String]$Identity # Syntax
    #   SYNTAX:     '[ProjectName | OrganizationName]\GroupName, UserPrincipalName, UserDisplayName'
    #   EXAMPLE:    '[MyProject]\Release Managers'
    Permission = [Hashtable]$Permissions # See 'Permission List'
}
```

## Permission Usage

``` PowerShell
AzDoTaskGroupPermission/Permissions/Permission
{
    PermissionName|PermissionDisplayName = [String]$Name { 'Allow, Deny' }
}
```

## Permission List

> Either 'Name' or 'DisplayName' can be used. The resource never hardcodes permission bits - it
> resolves the action by name (or display name) against the live `MetaTask` security namespace
> (`_apis/securitynamespaces`) at apply time, so this table is a reference, not the source of truth.

| Name | Note |
| ---- | ---- |
| Administer | Manage the task group's permissions. |
| Edit | Change the task group. |
| Delete | Delete the task group. |

## Properties

### Common Properties

- **ProjectName**: The name of the Azure DevOps project. This is the key property.
- **TaskGroupName**: The name of the task group. Omit it to target the project level, which every
  task group in the project inherits from.
- **isInherited**: Whether the task group inherits permissions from the project level. Defaults to `$true`.
- **Permissions**: A HashTable that specifies the permissions to be set. Refer to: 'Permissions Syntax'.
- **Ensure**: Specifies whether the permissions should exist. Valid values are `Present` and `Absent`.

## Additional Information

This resource manages the `MetaTask` security namespace, which secures task groups (see
[AzDoTaskGroup](AzDoTaskGroup.md)). The token is `{projectId}` for the project level and
`{projectId}/{taskGroupId}` for a single task group.

- **Only the listed identities are managed.** A task group's creator is granted *Administer* on it.
  When permissions are written, every other identity's entry is sent back unchanged, and
  `Ensure = 'Absent'` clears only the listed identities' entries.
- **A missing project or task group is reported as not found**, and nothing is written. Declare the
  `AzDoTaskGroup` resource first (`DependsOn`) when both are in the same configuration.

## Examples

## Example 1: Sample Configuration using AzDoTaskGroupPermission Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    Node localhost {
        AzDoTaskGroupPermission DeployStepsEditors {
            Ensure        = 'Present'
            ProjectName   = 'MyProject'
            TaskGroupName = 'Deploy web app'
            Permissions   = @(
                @{
                    Identity   = '[MyProject]\Release Managers'
                    Permission = @{
                        Edit = 'Allow'
                    }
                }
            )
        }
    }
}

ExampleConfig -OutputPath ./ExampleConfig
Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
$properties = @{
    ProjectName   = 'MyProject'
    TaskGroupName = 'Deploy web app'
    isInherited   = $true
    Permissions   = @(
        @{
            Identity   = '[MyProject]\Release Managers'
            Permission = @{
                Edit = 'Allow'
            }
        }
    )
}

Invoke-DscResource -Name 'AzDoTaskGroupPermission' -Method Get -Property $properties -ModuleName 'AzureDevOpsDscNative'
```
