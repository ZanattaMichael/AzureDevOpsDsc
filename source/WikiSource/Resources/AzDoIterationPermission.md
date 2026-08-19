# AzDoIterationPermission Resource

## Description

The `AzDoIterationPermission` DSC resource is used to manage permissions for specific iterations (sprints) within an Azure DevOps project. It allows you to configure which groups or users have access to work items in specific iterations and control their ability to edit, view, or manage iteration-related operations.

## Syntax

```powershell
AzDoIterationPermission [string] #ResourceName
{
    ProjectName = [String] $ProjectName
    [ IterationPath = [String] $IterationPath ]
    [ isInherited = [Boolean] $isInherited ]
    [ Permissions = [HashTable[]] $Permissions ]
    [ Ensure = [String] {'Present', 'Absent'} ]
    [ DependsOn = [String[]] ]
    [ PsDscRunAsCredential = [PSCredential] ]
}
```

## Properties

### Key Properties (Required)

- **ProjectName** [String] - The name of the Azure DevOps project.

### Optional Properties

- **IterationPath** [String] - The path of the iteration within the project (e.g., 'MyProject\Sprint 1'). If not specified, applies to project root iteration.

- **isInherited** [Boolean] - Whether the permissions are inherited from the parent iteration. Default is `$true`.

- **Permissions** [HashTable[]] - An array of ACE hashtables. Each entry has:
  - `Identity` - The group or user identity, e.g. `'[ProjectName]\TeamName'`
  - `Permission` - A hashtable mapping Iteration security-namespace bit names to `'Allow'` or `'Deny'`, e.g. `@{ WORK_ITEM_READ = 'Allow'; GENERIC_WRITE = 'Allow' }`

  See [Permissions & ACLs](../Permissions.md#azdoareapermission--azdoiterationpermission) for the full list of valid bit names (`GENERIC_READ`, `GENERIC_WRITE`, `CREATE_CHILDREN`, `DELETE`, `WORK_ITEM_READ`, `WORK_ITEM_WRITE`, `MANAGE_TEST_PLANS`, `MANAGE_TEST_SUITES`).

- **Ensure** [String] - Desired state of the resource:
  - `'Present'` - (default) Permissions should be configured
  - `'Absent'` - Permissions should be removed

### Common Properties

- **DependsOn** [String[]] - Dependencies on other resources. Use this to control the order of resource execution.

- **PsDscRunAsCredential** [PSCredential] - Credentials to run this resource under.

## Return Values

The resource returns the following properties:

- **ProjectName** - The name of the project
- **IterationPath** - The iteration path
- **isInherited** - Whether permissions are inherited
- **Permissions** - The configured permissions
- **Ensure** - Current state ('Present' or 'Absent')

## Examples

### Example 1: Grant Iteration Permissions to Team

```powershell
Configuration GrantIterationPermissions {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoIterationPermission 'SprintPermissions' {
            ProjectName   = 'MyProject'
            IterationPath = 'MyProject\Sprint 1'
            isInherited   = $false
            Permissions   = @(
                @{
                    Identity   = '[MyProject]\Development Team'
                    Permission = @{
                        WORK_ITEM_READ  = 'Allow'
                        WORK_ITEM_WRITE = 'Allow'
                    }
                },
                @{
                    Identity   = '[MyProject]\QA Team'
                    Permission = @{ WORK_ITEM_READ = 'Allow' }
                },
                @{
                    Identity   = '[MyProject]\Contractors'
                    Permission = @{ WORK_ITEM_WRITE = 'Deny' }
                }
            )
            Ensure = 'Present'
        }
    }
}

GrantIterationPermissions
Start-DscConfiguration -Path ./GrantIterationPermissions -Wait -Verbose
```

### Example 2: Configure Multiple Sprint Permissions

```powershell
Configuration ConfigureSprintPermissions {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoIterationPermission 'Sprint1' {
            ProjectName   = 'MyProject'
            IterationPath = 'MyProject\Sprint 1'
            isInherited   = $false
            Permissions   = @(
                @{
                    Identity   = '[MyProject]\Sprint 1 Team'
                    Permission = @{ GENERIC_WRITE = 'Allow' }
                }
            )
            Ensure = 'Present'
        }

        AzDoIterationPermission 'Sprint2' {
            ProjectName   = 'MyProject'
            IterationPath = 'MyProject\Sprint 2'
            isInherited   = $false
            Permissions   = @(
                @{
                    Identity   = '[MyProject]\Sprint 2 Team'
                    Permission = @{ GENERIC_WRITE = 'Allow' }
                }
            )
            Ensure = 'Present'
        }
    }
}

ConfigureSprintPermissions
Start-DscConfiguration -Path ./ConfigureSprintPermissions -Wait -Verbose
```

### Example 3: Disable Iteration Permission Inheritance

```powershell
Configuration DisableIterationInheritance {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoIterationPermission 'RestrictedSprint' {
            ProjectName   = 'MyProject'
            IterationPath = 'MyProject\Restricted Sprint'
            isInherited   = $false
            Permissions   = @(
                @{
                    Identity   = '[MyProject]\Project Admins'
                    Permission = @{ GENERIC_WRITE = 'Allow' }
                },
                @{
                    Identity   = '[MyProject]\Developers'
                    Permission = @{ GENERIC_READ = 'Allow' }
                }
            )
            Ensure = 'Present'
        }
    }
}

DisableIterationInheritance
Start-DscConfiguration -Path ./DisableIterationInheritance -Wait -Verbose
```

### Example 4: Query Iteration Permissions

```powershell
# Get the current state of iteration permissions
$properties = @{
    ProjectName   = 'MyProject'
    IterationPath = 'MyProject\Sprint 1'
}

$result = Invoke-DscResource -Name 'AzDoIterationPermission' `
    -Method Get `
    -Property $properties `
    -ModuleName 'AzureDevOpsDscNative'

$result | Select-Object ProjectName, IterationPath, isInherited, Permissions
```

### Example 5: Restrict Archived Sprint Access

```powershell
Configuration RestrictArchivedSprint {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoIterationPermission 'ArchivedSprintRead' {
            ProjectName   = 'MyProject'
            IterationPath = 'MyProject\Archived\Sprint 2024-Q1'
            isInherited   = $false
            Permissions   = @(
                @{
                    Identity   = '[MyProject]\Team Leads'
                    Permission = @{ GENERIC_READ = 'Allow' }
                },
                @{
                    Identity   = '[MyProject]\Developers'
                    Permission = @{ GENERIC_WRITE = 'Deny' }
                }
            )
            Ensure = 'Present'
        }
    }
}

RestrictArchivedSprint
Start-DscConfiguration -Path ./RestrictArchivedSprint -Wait -Verbose
```

### Example 6: Remove Iteration Permissions

```powershell
Configuration RemoveIterationPermissions {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoIterationPermission 'RemovePermissions' {
            ProjectName   = 'MyProject'
            IterationPath = 'MyProject\OldSprint'
            Ensure        = 'Absent'
        }
    }
}

RemoveIterationPermissions
Start-DscConfiguration -Path ./RemoveIterationPermissions -Wait -Verbose
```

## Important Notes

### Permission Types

The Iteration security namespace exposes these bit names (see [Permissions & ACLs](../Permissions) for the full table):

- **GENERIC_READ** - View this node
- **GENERIC_WRITE** - Edit this node
- **CREATE_CHILDREN** - Create child nodes
- **DELETE** - Delete this node
- **WORK_ITEM_READ** - View work items in this node
- **WORK_ITEM_WRITE** - Edit work items in this node
- **MANAGE_TEST_PLANS** - Manage test plans
- **MANAGE_TEST_SUITES** - Manage test suites

### Iteration Hierarchy

- Iterations are organized in a hierarchy (parent/child relationships)
- Permissions cascade from parent to child iterations
- Setting `isInherited` to `$false` allows custom permissions per iteration

### Iteration Path Format

- Use backslash as separator (e.g., 'Project\Iteration1\Sprint1')
- Project name is typically the root
- Paths are case-sensitive

## Troubleshooting

### Issue: "Iteration Path Not Found"

**Cause**: The specified iteration does not exist

**Solution**:
```powershell
# Verify the iteration exists in the project
# Use AzDoIterationNodes resource to create iterations first
# Check the exact spelling and case of the iteration path
```

### Issue: "Cannot Set Iteration Permissions"

**Cause**: Insufficient permissions or group does not exist

**Solution**:
- Verify user has project administrator permissions
- Check that the group exists in the organization or project
- Ensure the personal access token has sufficient scope

### Issue: "Permissions Not Applying Correctly"

**Cause**: Inheritance conflicts or parent permissions override

**Solution**:
```powershell
# Set isInherited to $false to override parent permissions
# Explicitly configure all required permissions
# Check for conflicting permission rules
```

## Related Resources

- [AzDoIterationNodes](AzDoIterationNodes) - Manage iteration nodes in a project
- [AzDoAreaPermission](AzDoAreaPermission) - Manage area permissions
- [AzDoProjectPermission](AzDoProjectPermission) - Manage project-level permissions
- [AzDoGroupPermission](AzDoGroupPermission) - Manage group permissions

## See Also

- [Azure DevOps Documentation](https://docs.microsoft.com/en-us/azure/devops/)
- [PowerShell DSC Documentation](https://docs.microsoft.com/en-us/powershell/dsc/overview)
- [AzureDevOpsDscNative Home](../Home)
