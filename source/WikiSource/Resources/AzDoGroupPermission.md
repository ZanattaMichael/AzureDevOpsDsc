# AzDoGroupPermission Resource

## Description

The `AzDoGroupPermission` DSC resource manages permissions (ACEs) for a single Azure DevOps group. Unlike most other permission resources in this module, `AzDoGroupPermission` does not target a project/repository/pipeline scope — it manages the ACL entries that apply to identities *for the group itself* (the group's own security descriptor), keyed only by the group's descriptor name.

> **Verified against source:** `source/Classes/009.AzDoGroupPermission.ps1` in the `AzureDevOpsDscNative` repository.

## Syntax

```powershell
AzDoGroupPermission [string] #ResourceName
{
    GroupName = [String] $GroupName
    [ isInherited = [Boolean] $isInherited ]
    [ Permissions = [HashTable[]] $Permissions ]
    [ Ensure = [String] {'Present', 'Absent'} ]
    [ DependsOn = [String[]] ]
    [ PsDscRunAsCredential = [PSCredential] ]
}
```

## Properties

### Key Properties (Required)

- **GroupName** [String] - The name (or `[Project]\GroupName` descriptor path) of the group whose permissions are being managed. Aliased as `Name`.

### Optional Properties

- **isInherited** [Boolean] - Whether the permissions are inherited from a parent group. Default is `$true`.

- **Permissions** [HashTable[]] - An array of ACE hashtables. Each entry has:
  - `Identity` - The identity/group the ACE applies to (e.g. `'this'` to refer to the group itself, or `'[Project]\GroupName'`)
  - `Permission` - A hashtable mapping permission bit names to `'Allow'` or `'Deny'` (e.g. `@{ Read = 'Allow'; Write = 'Allow' }`)

- **Ensure** [String] - Desired state of the resource:
  - `'Present'` - (default) Permissions should be configured
  - `'Absent'` - Permissions should be removed

### Common Properties

- **DependsOn** [String[]] - Dependencies on other resources.

- **PsDscRunAsCredential** [PSCredential] - Credentials to run this resource under.

> **Note:** This resource has **no** `ProjectName`, `PermissionName`, `Allow`, or `Deny` top-level properties. Earlier drafts of this page documented those; they do not exist on the class. Permission bit names and their Allow/Deny state live inside each `Permissions` entry's `Permission` hashtable, as shown above.

## Return Values

- **GroupName** - The group name
- **isInherited** - Whether permissions are inherited
- **Permissions** - The configured permissions
- **Ensure** - Current state ('Present' or 'Absent')

## Examples

### Example 1: Grant Permissions on a Group's Own Descriptor

```powershell
Configuration GrantGroupPermission {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    Node localhost {
        AzDoGroupPermission 'ReadersGroupPermission' {
            Ensure      = 'Present'
            GroupName   = '[MyProject]\Readers'
            isInherited = $false
            Permissions = @(
                @{
                    Identity   = 'this'
                    Permission = @{
                        Read  = 'Allow'
                        Write = 'Allow'
                    }
                }
            )
        }
    }
}

GrantGroupPermission
Start-DscConfiguration -Path ./GrantGroupPermission -Wait -Verbose
```

### Example 2: Grant Another Group Rights Over This Group

```powershell
Configuration CrossGroupPermission {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    Node localhost {
        AzDoGroupPermission 'DevelopersManagedByAdmins' {
            Ensure      = 'Present'
            GroupName   = '[MyProject]\Developers'
            isInherited = $false
            Permissions = @(
                @{
                    Identity   = '[MyProject]\Group1'
                    Permission = @{
                        Read  = 'Allow'
                        Write = 'Allow'
                    }
                }
            )
        }
    }
}

CrossGroupPermission
Start-DscConfiguration -Path ./CrossGroupPermission -Wait -Verbose
```

### Example 3: Change Permissions for an Existing Entry

```powershell
Configuration UpdateGroupPermission {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    Node localhost {
        AzDoGroupPermission 'DevelopersUpdated' {
            Ensure      = 'Present'
            GroupName   = '[MyProject]\Developers'
            isInherited = $false
            Permissions = @(
                @{
                    Identity   = '[MyProject]\Group1'
                    Permission = @{
                        Read  = 'Allow'
                        Write = 'Deny'
                    }
                }
            )
        }
    }
}

UpdateGroupPermission
Start-DscConfiguration -Path ./UpdateGroupPermission -Wait -Verbose
```

### Example 4: Query Current Permissions

```powershell
$properties = @{
    GroupName = '[MyProject]\Readers'
}

$result = Invoke-DscResource -Name 'AzDoGroupPermission' `
    -Method Get `
    -Property $properties `
    -ModuleName 'AzureDevOpsDscNative'

$result | Select-Object GroupName, isInherited, Permissions
```

### Example 5: Remove a Group's Explicit Permissions

```powershell
Configuration RemoveGroupPermission {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    Node localhost {
        AzDoGroupPermission 'RemoveDeveloperPerms' {
            Ensure    = 'Absent'
            GroupName = '[MyProject]\Developers'
        }
    }
}

RemoveGroupPermission
Start-DscConfiguration -Path ./RemoveGroupPermission -Wait -Verbose
```

## Important Notes

### Permission Bit Names

The valid keys inside each `Permission` hashtable are the ActionName values defined by the Identity security namespace for the group being managed (e.g. `Read`, `Write`), and are confirmed against this module's integration test suite (`tests/Integration/Resources/AzDoGroupPermission.tests.ps1`). See [Permissions](../Permissions) for how to discover the full bit list for a namespace.

### `isInherited`

- When `$true` (default), the group inherits ACEs from its parent scope.
- Setting `isInherited` to `$false` breaks inheritance so only the entries you list apply.

## Related Resources

- [AzDoOrganizationGroup](AzDoOrganizationGroup) - Create organization groups
- [AzDoProjectGroup](AzDoProjectGroup) - Create project groups
- [AzDoGroupMember](AzDoGroupMember) - Add members to groups
- [AzDoProjectPermission](AzDoProjectPermission) - Project-level permissions
- [Permissions overview](../Permissions) - Conceptual guide to permission resources

## See Also

- [Azure DevOps Permissions Documentation](https://docs.microsoft.com/en-us/azure/devops/organizations/security/permissions)
- [AzureDevOpsDscNative Home](../Home)
