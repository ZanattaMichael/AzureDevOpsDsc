# DSC AzDoOrganizationPermission Resource

## Syntax

```PowerShell
AzDoOrganizationPermission [string] #ResourceName
{
    GroupName     = [String]$GroupName
    [ Permissions = [HashTable[]]$Permissions ]
    [ Ensure      = [String] {'Present', 'Absent'} ]
}
```

## Permissions Syntax

``` PowerShell
AzDoOrganizationPermission/Permissions
{
    Identity   = [String]$Identity # Syntax
    #   SYNTAX:     '[OrganizationName]\GroupName, UserPrincipalName, UserDisplayName'
    #   EXAMPLE:    '[MyOrg]\Project Creators'
    Permission = [Hashtable]$Permissions # See 'Permission List'
}
```

## Permission Usage

``` PowerShell
AzDoOrganizationPermission/Permissions/Permission
{
    PermissionName|PermissionDisplayName = [String]$Name { 'Allow, Deny' }
}
```

## Permission List

> Either 'Name' or 'DisplayName' can be used. The resource never hardcodes permission bits - it
> resolves the action by name (or display name) against the live `Collection` security namespace
> (`_apis/securitynamespaces`) at apply time, so this table is a reference, not the source of truth.

| DisplayName | Note |
| ----------- | ---- |
| View instance-level information | See organization-level settings and membership. |
| Edit instance-level information | Change organization-level settings and groups. |
| Create new projects | Create projects in the organization. |
| Delete field from organization | Delete work item fields from the organization. |
| Manage enterprise policies | Change organization policies. |
| Manage process template | Create, edit and delete processes. |

## Properties

### Common Properties

- **GroupName**: The group this configuration block is for. It is the key property, so each group
  can be configured in its own block. Use the format `[OrganizationName]\GroupName`.
- **Permissions**: A HashTable that specifies the permissions to be set. Refer to: 'Permissions Syntax'.
- **Ensure**: Specifies whether the permissions should exist. Valid values are `Present` and `Absent`.

## Additional Information

This resource manages the organization-level permissions in the `Collection` security namespace -
the permissions shown under *Organization settings > Permissions*.

- **Only the listed identities are managed.** The organization root holds the grants every member of
  the organization relies on. When permissions are written, every other identity's entry is sent back
  unchanged, and `Ensure = 'Absent'` clears only the listed identities' entries. The organization ACL
  itself is never deleted.
- **There is no `isInherited` property.** The organization root has no parent to inherit from; the
  ACL's inheritance flag is written back exactly as it was read.
- **The root token is read, not assumed.** If no root ACL is found in the namespace, `Get` reports an
  error that lists the tokens it saw, and `Set` refuses to write.

## Examples

## Example 1: Sample Configuration using AzDoOrganizationPermission Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    Node localhost {
        AzDoOrganizationPermission ProjectCreators {
            Ensure      = 'Present'
            GroupName   = '[MyOrg]\Project Creators'
            Permissions = @(
                @{
                    Identity   = '[MyOrg]\Project Creators'
                    Permission = @{
                        'Create new projects' = 'Allow'
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
    GroupName   = '[MyOrg]\Project Creators'
    Permissions = @(
        @{
            Identity   = '[MyOrg]\Project Creators'
            Permission = @{
                'Create new projects' = 'Allow'
            }
        }
    )
}

Invoke-DscResource -Name 'AzDoOrganizationPermission' -Method Get -Property $properties -ModuleName 'AzureDevOpsDscNative'
```
