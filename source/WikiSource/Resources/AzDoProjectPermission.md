# AzDoProjectPermission Resource

## Description

The `AzDoProjectPermission` DSC resource is used to manage permissions at the project level in Azure DevOps. It allows you to configure and enforce the desired state of permissions assigned to groups for an entire project, controlling high-level access to project features and administration capabilities. These permissions cascade to project-level resources unless overridden by more specific permissions.

## Syntax

```powershell
AzDoProjectPermission [string] #ResourceName
{
    ProjectName = [String] $ProjectName
    GroupName = [String] $GroupName
    [ isInherited = [Boolean] $isInherited ]
    [ Permissions = [Hashtable[]] $Permissions ]
    [ Ensure = [String] {'Present', 'Absent'} ]
    [ DependsOn = [String[]] ]
    [ PsDscRunAsCredential = [PSCredential] ]
}
```

## Properties

### Key Properties (Required)

- **ProjectName** [String] - The name of the Azure DevOps project. This is the unique identifier for the project at which permissions are managed.

### Mandatory Properties

- **GroupName** [String] - The name of the group to which project-level permissions are assigned. The group must exist in the project or organization.

### Optional Properties

- **isInherited** [Boolean] - Specifies whether the permissions are inherited from the organization level. Default is `$true`. When set to `$false`, only explicitly assigned permissions apply.

- **Permissions** [Hashtable[]] - An array of ACE hashtables. Each entry has:
  - `Identity` - The group or user identity, e.g. `'[ProjectName]\GroupName'` (conventionally matching `GroupName` above)
  - `Permission` - A hashtable mapping Project security-namespace bit names to `'Allow'` or `'Deny'`, e.g. `@{ GENERIC_READ = 'Allow'; GENERIC_WRITE = 'Allow' }`

  See [Permissions & ACLs](../Permissions.md#azdoprojectpermission) for the full list of valid bit names (`GENERIC_READ`, `GENERIC_WRITE`, `DELETE`, `RENAME`, `WORK_ITEM_DELETE`, `WORK_ITEM_MOVE`, etc.).

- **Ensure** [String] - Desired state of the resource:
  - `'Present'` - (default) Project permissions should exist
  - `'Absent'` - Project permissions should be removed

### Common Properties

- **DependsOn** [String[]] - Dependencies on other resources. Use this to control the order of resource execution.

- **PsDscRunAsCredential** [PSCredential] - Credentials to run this resource under.

## Return Values

The resource returns the following properties:

- **ProjectName** - The name of the project
- **GroupName** - The name of the group
- **isInherited** - Whether permissions are inherited
- **Permissions** - The current project-level permissions assigned
- **Ensure** - Current state ('Present' or 'Absent')

## Examples

### Example 1: Grant Read-Only Access to Project

```powershell
Configuration GrantProjectRead {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoProjectPermission 'ReadersProjectAccess' {
            ProjectName = 'MyProject'
            GroupName   = '[MyProject]\Readers'
            isInherited = $false
            Permissions = @(
                @{
                    Identity   = '[MyProject]\Readers'
                    Permission = @{ GENERIC_READ = 'Allow' }
                }
            )
            Ensure = 'Present'
        }
    }
}

GrantProjectRead
Start-DscConfiguration -Path ./GrantProjectRead -Wait -Verbose
```

### Example 2: Configure Contributor Permissions

```powershell
Configuration GrantProjectContribute {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoProjectPermission 'ContributorsProjectAccess' {
            ProjectName = 'MyProject'
            GroupName   = '[MyProject]\Contributors'
            isInherited = $false
            Permissions = @(
                @{
                    Identity   = '[MyProject]\Contributors'
                    Permission = @{
                        GENERIC_READ  = 'Allow'
                        GENERIC_WRITE = 'Allow'
                    }
                }
            )
            Ensure = 'Present'
        }
    }
}

GrantProjectContribute
Start-DscConfiguration -Path ./GrantProjectContribute -Wait -Verbose
```

### Example 3: Configure Project Administration Access

```powershell
Configuration GrantProjectAdmin {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoProjectPermission 'AdminsProjectAccess' {
            ProjectName = 'MyProject'
            GroupName   = '[MyProject]\Project Administrators'
            isInherited = $false
            Permissions = @(
                @{
                    Identity   = '[MyProject]\Project Administrators'
                    Permission = @{
                        GENERIC_READ  = 'Allow'
                        GENERIC_WRITE = 'Allow'
                        RENAME        = 'Allow'
                        DELETE        = 'Allow'
                    }
                }
            )
            Ensure = 'Present'
        }
    }
}

GrantProjectAdmin
Start-DscConfiguration -Path ./GrantProjectAdmin -Wait -Verbose
```

### Example 4: Configure Role-Based Project Permissions

```powershell
Configuration ConfigureRoleBasedProjectPermissions {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        # Readers group - View-only access
        AzDoProjectPermission 'ReadersAccess' {
            ProjectName = 'MyProject'
            GroupName   = '[MyProject]\Readers'
            isInherited = $false
            Permissions = @(
                @{
                    Identity   = '[MyProject]\Readers'
                    Permission = @{ GENERIC_READ = 'Allow' }
                }
            )
            Ensure = 'Present'
        }
        
        # Developers group - Read and write
        AzDoProjectPermission 'DevelopersAccess' {
            ProjectName = 'MyProject'
            GroupName   = '[MyProject]\Developers'
            isInherited = $false
            Permissions = @(
                @{
                    Identity   = '[MyProject]\Developers'
                    Permission = @{
                        GENERIC_READ      = 'Allow'
                        GENERIC_WRITE     = 'Allow'
                        WORK_ITEM_DELETE  = 'Allow'
                    }
                }
            )
            Ensure = 'Present'
        }
        
        # Administrators group - Full control
        AzDoProjectPermission 'AdminsAccess' {
            ProjectName = 'MyProject'
            GroupName   = '[MyProject]\Project Administrators'
            isInherited = $false
            Permissions = @(
                @{
                    Identity   = '[MyProject]\Project Administrators'
                    Permission = @{
                        GENERIC_READ              = 'Allow'
                        GENERIC_WRITE             = 'Allow'
                        DELETE                    = 'Allow'
                        RENAME                    = 'Allow'
                        WORK_ITEM_DELETE          = 'Allow'
                        WORK_ITEM_PERMANENTLY_DELETE = 'Allow'
                    }
                }
            )
            Ensure = 'Present'
        }
    }
}

ConfigureRoleBasedProjectPermissions
Start-DscConfiguration -Path ./ConfigureRoleBasedProjectPermissions -Wait -Verbose
```

### Example 5: Using Invoke-DscResource to Manage Permissions

```powershell
# Get current project permissions
$properties = @{
    ProjectName = 'MyProject'
    GroupName   = '[MyProject]\Developers'
}

$result = Invoke-DscResource -Name 'AzDoProjectPermission' `
    -Method Get `
    -Property $properties `
    -ModuleName 'AzureDevOpsDscNative'

$result | Select-Object ProjectName, GroupName, isInherited, Permissions

# Set new project permissions
$setProperties = @{
    ProjectName = 'MyProject'
    GroupName   = '[MyProject]\Developers'
    isInherited = $false
    Permissions = @(
        @{
            Identity   = '[MyProject]\Developers'
            Permission = @{
                GENERIC_READ  = 'Allow'
                GENERIC_WRITE = 'Allow'
            }
        }
    )
    Ensure = 'Present'
}

Invoke-DscResource -Name 'AzDoProjectPermission' `
    -Method Set `
    -Property $setProperties `
    -ModuleName 'AzureDevOpsDscNative'
```

## Important Notes

### Permission Bit Names

Project-level permissions use the `$PROJECT` security namespace. Key bit names (see [Permissions & ACLs](../Permissions.md#azdoprojectpermission) for the full table):

- **GENERIC_READ** — View project-level information
- **GENERIC_WRITE** — Edit project-level information
- **RENAME** — Rename the team project
- **DELETE** — Delete the team project (grant sparingly)
- **WORK_ITEM_DELETE** — Delete and restore work items
- **WORK_ITEM_MOVE** — Move work items out of this project
- **WORK_ITEM_PERMANENTLY_DELETE** — Permanently delete work items
- **BYPASS_RULES** — Bypass rules on work item updates
- **SUPPRESS_NOTIFICATIONS** — Suppress notifications for work item updates

### Permission Hierarchy

- Organization-level permissions provide the baseline
- Project-level permissions override organization permissions
- Specific resource permissions (repository, pipeline, etc.) override project permissions
- Inheritance follows the principle of least privilege when properly configured

### Cascading Behavior

- Project-level permissions cascade to most project resources
- Repository, pipeline, and variable group permissions can override project permissions
- Area and iteration permissions are independent
- Team/group permissions may further restrict access

### Common Permission Patterns

- **Read-Only Teams**: Grant only `GENERIC_READ`
- **Development Teams**: Grant `GENERIC_READ`, `GENERIC_WRITE`, `WORK_ITEM_DELETE`
- **Team Leads**: Grant `GENERIC_READ`, `GENERIC_WRITE`, `RENAME`, `WORK_ITEM_DELETE`
- **Administrators**: Grant all bits above plus `DELETE`, `WORK_ITEM_PERMANENTLY_DELETE`

## Troubleshooting

### Issue: "Project Not Found"

**Cause**: The specified project does not exist in the organization.

**Solution**:
```powershell
# Verify the project name exists
# Check Azure DevOps Projects page
# Ensure the exact project name is used (case-sensitive)
```

### Issue: "Group Not Found"

**Cause**: The specified group does not exist in the project or organization.

**Solution**:
```powershell
# Create the group using AzDoProjectGroup or AzDoOrganizationGroup first
# Verify the group name is correct
# Check group existence in project or organization settings
```

### Issue: "Permissions Affecting Subresources Unexpectedly"

**Cause**: Permission inheritance is affecting resource-specific permissions.

**Solution**:
```powershell
# Set isInherited = $false for precise control
# Configure resource-specific permissions to override project permissions
# Document permission hierarchy in your configuration
```

## Related Resources

- [AzDoProject](AzDoProject.md) - Create and manage projects
- [AzDoProjectGroup](AzDoProjectGroup.md) - Manage project-level groups
- [AzDoGroupPermission](AzDoGroupPermission.md) - Manage group permissions within projects
- [AzDoGitPermission](AzDoGitPermission.md) - Manage repository permissions
- [AzDoPipelinePermission](AzDoPipelinePermission.md) - Manage pipeline permissions

## See Also

- [Azure DevOps Project-Level Permissions](https://docs.microsoft.com/en-us/azure/devops/organizations/security/permissions-reference#project-level-permissions)
- [Azure DevOps Security Namespaces Documentation](https://docs.microsoft.com/en-us/azure/devops/organizations/security/namespace-reference)
- [PowerShell DSC Documentation](https://docs.microsoft.com/en-us/powershell/dsc/overview)
- [AzureDevOpsDscNative Home](../Home.md)
