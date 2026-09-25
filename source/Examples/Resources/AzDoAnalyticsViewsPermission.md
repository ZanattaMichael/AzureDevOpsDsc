# DSC AzDoAnalyticsViewsPermission Resource

## Syntax

```PowerShell
AzDoAnalyticsViewsPermission [string] #ResourceName
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
AzDoAnalyticsViewsPermission/Permissions
{
    Identity   = [String]$Identity # Syntax
    #   SYNTAX:     '[ProjectName | OrganizationName]\ServicePrincipalName, UserPrincipalName, UserDisplayName, GroupDisplayName'
    #   EXAMPLE:    '[TestProject]\Contributors'
    Permission = [Hashtable]$Permissions # See 'Permission List'
}
```

## Permission Usage

``` PowerShell
AzDoAnalyticsViewsPermission/Permissions/Permission
{
    PermissionName|PermissionDisplayName = [String]$Name { 'Allow, Deny' }
}
```

## Permission List

> Either 'Name' or 'DisplayName' can be used. The resource never hardcodes permission bits - it
> resolves the action by name (or display name) against the live `AnalyticsViews` security namespace
> (`_apis/securitynamespaces`) at apply time, so this table is a reference, not the source of truth.

| Name | Note |
| ---- | ---- |
| Read | View a shared Analytics view. |
| Write | Edit a shared Analytics view. |
| Delete | Delete a shared Analytics view. |

## Properties

### Common Properties

- **ProjectName**: The name of the Azure DevOps project. This property is mandatory and serves as the key property for the resource.
- **GroupName**: The name of the group to grant analytics views permissions to. Use the format `[ProjectName]\GroupName`.
- **isInherited**: Whether permissions are inherited from parent objects. Defaults to `$true`.
- **Permissions**: A HashTable that specifies the permissions to be set. Refer to: 'Permissions Syntax'.
- **Ensure**: Specifies whether the permissions should exist. Valid values are `Present` and `Absent`.

## Additional Information

This resource manages permissions on the project-scoped `AnalyticsViews` security namespace, which
governs who can view shared Analytics views (token shape `$/Shared/{projectId}`).

## Examples

## Example 1: Sample Configuration using AzDoAnalyticsViewsPermission Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    Node localhost {
        AzDoAnalyticsViewsPermission AddAnalyticsViewsPermission {
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

Invoke-DscResource -Name 'AzDoAnalyticsViewsPermission' -Method Get -Property $properties -ModuleName 'AzureDevOpsDscNative'
```
