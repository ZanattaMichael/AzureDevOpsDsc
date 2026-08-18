# AzDoAreaPermission Resource

## Description

The `AzDoAreaPermission` DSC resource is used to manage permissions for specific areas within an Azure DevOps project. It allows you to configure which groups or users have access to work items in specific project areas and whether they can edit, delete, or perform other area-related operations.

## Syntax

```powershell
AzDoAreaPermission [string] #ResourceName
{
    ProjectName = [String] $ProjectName
    [ AreaPath = [String] $AreaPath ]
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

- **AreaPath** [String] - The path of the area within the project (e.g., 'MyProject\Area1\SubArea'). If not specified, applies to project root area.

- **isInherited** [Boolean] - Whether the permissions are inherited from the parent area. Default is `$true`.

- **Permissions** [HashTable[]] - An array of ACE hashtables. Each entry has:
  - `Identity` - The group or user identity, e.g. `'[ProjectName]\TeamName'`
  - `Permission` - A hashtable mapping CSS (Area/Iteration) security-namespace bit names to `'Allow'` or `'Deny'`, e.g. `@{ WORK_ITEM_READ = 'Allow'; GENERIC_WRITE = 'Allow' }`

> **Verified against source:** `source/Classes/042.AzDoAreaPermission.ps1`. This class has no `Allow`/`Deny` boolean flags at the entry level — Allow/Deny is expressed per bit name inside the `Permission` hashtable, confirmed by `tests/Integration/Resources/AzDoAreaPermission.tests.ps1`.

- **Ensure** [String] - Desired state of the resource:
  - `'Present'` - (default) Permissions should be configured
  - `'Absent'` - Permissions should be removed

### Common Properties

- **DependsOn** [String[]] - Dependencies on other resources. Use this to control the order of resource execution.

- **PsDscRunAsCredential** [PSCredential] - Credentials to run this resource under.

## Return Values

The resource returns the following properties:

- **ProjectName** - The name of the project
- **AreaPath** - The area path
- **isInherited** - Whether permissions are inherited
- **Permissions** - The configured permissions
- **Ensure** - Current state ('Present' or 'Absent')

## Examples

### Example 1: Grant Area Permissions to a Group

```powershell
Configuration GrantAreaPermissions {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoAreaPermission 'FrontendAreaPermission' {
            ProjectName = 'MyProject'
            AreaPath    = 'MyProject\Frontend'
            isInherited = $false
            Permissions = @(
                @{
                    Identity   = '[MyProject]\Frontend Team'
                    Permission = @{
                        WORK_ITEM_READ  = 'Allow'
                        WORK_ITEM_WRITE = 'Allow'
                    }
                },
                @{
                    Identity   = '[MyProject]\Backend Team'
                    Permission = @{
                        WORK_ITEM_READ  = 'Allow'
                        WORK_ITEM_WRITE = 'Deny'
                    }
                }
            )
            Ensure = 'Present'
        }
    }
}

GrantAreaPermissions
Start-DscConfiguration -Path ./GrantAreaPermissions -Wait -Verbose
```

### Example 2: Configure Area Hierarchy Permissions

```powershell
Configuration AreaHierarchyPermissions {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoAreaPermission 'RootArea' {
            ProjectName = 'MyProject'
            AreaPath    = 'MyProject'
            isInherited = $false
            Permissions = @(
                @{
                    Identity   = '[MyProject]\Project Admins'
                    Permission = @{ GENERIC_WRITE = 'Allow' }
                }
            )
            Ensure = 'Present'
        }
        
        AzDoAreaPermission 'SubArea1' {
            ProjectName = 'MyProject'
            AreaPath    = 'MyProject\Team1'
            isInherited = $true
            Permissions = @(
                @{
                    Identity   = '[MyProject]\Team 1'
                    Permission = @{ GENERIC_WRITE = 'Allow' }
                }
            )
            Ensure = 'Present'
            DependsOn  = '[AzDoAreaPermission]RootArea'
        }
    }
}

AreaHierarchyPermissions
Start-DscConfiguration -Path ./AreaHierarchyPermissions -Wait -Verbose
```

### Example 3: Query Current Area Permissions

```powershell
# Get the current state of area permissions
$properties = @{
    ProjectName = 'MyProject'
    AreaPath    = 'MyProject\Frontend'
}

$result = Invoke-DscResource -Name 'AzDoAreaPermission' `
    -Method Get `
    -Property $properties `
    -ModuleName 'AzureDevOpsDscNative'

$result | Select-Object ProjectName, AreaPath, isInherited, Permissions
```

### Example 4: Disable Permission Inheritance

```powershell
Configuration DisableInheritance {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoAreaPermission 'ExclusiveArea' {
            ProjectName = 'MyProject'
            AreaPath    = 'MyProject\ExclusiveWork'
            isInherited = $false
            Permissions = @(
                @{
                    Identity   = '[MyProject]\Special Team'
                    Permission = @{ GENERIC_WRITE = 'Allow' }
                },
                @{
                    Identity   = '[MyProject]\Everyone'
                    Permission = @{ GENERIC_WRITE = 'Deny' }
                }
            )
            Ensure = 'Present'
        }
    }
}

DisableInheritance
Start-DscConfiguration -Path ./DisableInheritance -Wait -Verbose
```

### Example 5: Remove Area Permissions

```powershell
Configuration RemoveAreaPermissions {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoAreaPermission 'RemovePermissions' {
            ProjectName = 'MyProject'
            AreaPath    = 'MyProject\OldArea'
            Ensure      = 'Absent'
        }
    }
}

RemoveAreaPermissions
Start-DscConfiguration -Path ./RemoveAreaPermissions -Wait -Verbose
```

## Important Notes

### Permission Types

- **Edit** - Ability to create and modify work items
- **View** - Ability to view work items
- **Delete** - Ability to delete work items
- **Manage** - Ability to manage area-level settings

### Inheritance Behavior

- When `isInherited` is `$true`, permissions flow from parent to child areas
- Setting `isInherited` to `$false` breaks inheritance and allows custom permissions
- Child areas without explicit permissions inherit from parents

### Area Path Format

- Use backslash as separator (e.g., 'Project\Area1\SubArea')
- Project name should be included in the path
- Paths are case-sensitive

## Troubleshooting

### Issue: "Area Path Not Found"

**Cause**: The specified area path does not exist

**Solution**:
```powershell
# Verify the area exists in the project
# Use AzDoAreaNodes resource to create areas first
# Check the exact spelling and case of the area path
```

### Issue: "Cannot Set Permissions"

**Cause**: Insufficient permissions or invalid group identity

**Solution**:
- Verify user has project-level administrator permissions
- Check that the group exists in the organization or project
- Ensure the personal access token has sufficient scope

### Issue: "Permission Changes Not Applied"

**Cause**: Inheritance is preventing changes or conflicts exist

**Solution**:
```powershell
# Set isInherited to $false to override parent permissions
# Explicitly set all required permissions
# Check for conflicting Allow/Deny rules
```

## Related Resources

- [AzDoAreaNodes](AzDoAreaNodes.md) - Manage area nodes in a project
- [AzDoIterationPermission](AzDoIterationPermission.md) - Manage iteration permissions
- [AzDoProjectPermission](AzDoProjectPermission.md) - Manage project-level permissions
- [AzDoGroupPermission](AzDoGroupPermission.md) - Manage group permissions

## See Also

- [Azure DevOps Documentation](https://docs.microsoft.com/en-us/azure/devops/)
- [PowerShell DSC Documentation](https://docs.microsoft.com/en-us/powershell/dsc/overview)
- [AzureDevOpsDscNative Home](../Home.md)
