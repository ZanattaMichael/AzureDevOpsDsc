# DSC AzDoTaggingPermission Resource

## Syntax

```PowerShell
AzDoTaggingPermission [string] #ResourceName
{
    ProjectName   = [String]$ProjectName
    GroupName     = [String]$GroupName
    [ isInherited = [Boolean]$isInherited ]
    [ Permissions = [HashTable[]]$Permissions ]
    [ Ensure      = [String] {'Present', 'Absent'} ]
}
```

## Permissions Syntax

``` PowerShell
AzDoTaggingPermission/Permissions
{
    Identity   = [String]$Identity # Syntax
    #   SYNTAX:     '[ProjectName | OrganizationName]\ServicePrincipalName, UserPrincipalName, UserDisplayName, GroupDisplayName'
    #   EXAMPLE:    '[TestProject]\Contributors'
    Permission = [Hashtable]$Permissions # See 'Permission List'
}
```

## Permission Usage

``` PowerShell
AzDoTaggingPermission/Permissions/Permission
{
    PermissionName|PermissionDisplayName = [String]$Name { 'Allow, Deny' }
}
```

## Permission List

> Either 'Name' or 'DisplayName' can be used. The resource never hardcodes permission bits - it
> resolves the action by name (or display name) against the live `Tagging` security namespace
> (`_apis/securitynamespaces`) at apply time, so this table is a reference, not the source of truth.

| DisplayName | Note |
| ----------- | ---- |
| Create tag definition | Controls who can add new work item tags in the project. |

## Properties

### Common Properties

- **ProjectName**: The name of the Azure DevOps project. This property is mandatory and serves as the key property for the resource.
- **GroupName**: The name of the group to grant tagging permissions to. Use the format `[ProjectName]\GroupName`.
- **isInherited**: Whether permissions are inherited from parent objects. Defaults to `$true`.
- **Permissions**: A HashTable that specifies the permissions to be set. Refer to: 'Permissions Syntax'.
- **Ensure**: Specifies whether the permissions should exist. Valid values are `Present` and `Absent`.

## Additional Information

This resource manages permissions on the project-scoped `Tagging` security namespace, which
governs who can create work item tags (token shape `/{projectId}`).

## Examples

## Example 1: Sample Configuration using AzDoTaggingPermission Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    Node localhost {
        AzDoTaggingPermission AddTaggingPermission {
            Ensure      = 'Present'
            ProjectName = 'MyProject'
            GroupName   = '[MyProject]\Contributors'
            isInherited = $false
            Permissions = @(
                @{
                    Identity   = '[MyProject]\Contributors'
                    Permission = @{
                        'Create tag definition' = 'Deny'
                    }
                }
            )
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
$properties = @{
    ProjectName = 'MyProject'
    GroupName   = '[MyProject]\Contributors'
    isInherited = $false
    Permissions = @(
        @{
            Identity   = '[MyProject]\Contributors'
            Permission = @{
                'Create tag definition' = 'Deny'
            }
        }
    )
}

Invoke-DscResource -Name 'AzDoTaggingPermission' -Method Get -Property $properties -ModuleName 'AzureDevOpsDscNative'
```
