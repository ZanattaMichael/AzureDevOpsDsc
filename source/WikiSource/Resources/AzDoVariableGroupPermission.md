# AzDoVariableGroupPermission Resource

## Description

The `AzDoVariableGroupPermission` DSC resource is used to manage role-based permissions for variable groups in Azure DevOps. It allows you to control which groups and users can view, edit, manage, or use variable groups, ensuring sensitive variables are protected and accessible only to authorized users.

## Syntax

```powershell
AzDoVariableGroupPermission [string] #ResourceName
{
    ProjectName = [String] $ProjectName
    VariableGroupName = [String] $VariableGroupName
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

- **ProjectName** [String] - The name of the Azure DevOps project.

- **VariableGroupName** [String] - The name of the variable group.

- **GroupName** [String] - The name of the group whose permissions are being managed.

### Optional Properties

- **isInherited** [Boolean] - Whether permissions are inherited from the project level. Default is `$true`.

- **Permissions** [HashTable[]] - An array of ACE hashtables. Each entry has:
  - `Identity` - The group or user identity, e.g. `'[ProjectName]\GroupName'` (conventionally matching `GroupName` above)
  - `Permission` - A hashtable mapping Variable Group (Library) security-namespace bit names to `'Allow'` or `'Deny'`, e.g. `@{ View = 'Allow'; Use = 'Allow' }`

  See [Permissions & ACLs](../Permissions.md#azdovariablegrouppermission) for the full list of valid bit names (`View`, `Administer`, `Create`, `ViewSecrets`, `Use`, `Owner`).

- **Ensure** [String] - Desired state of the resource:
  - `'Present'` - (default) Permissions should be configured
  - `'Absent'` - Permissions should be removed

### Common Properties

- **DependsOn** [String[]] - Dependencies on other resources. Use this to control the order of resource execution.

- **PsDscRunAsCredential** [PSCredential] - Credentials to run this resource under.

## Return Values

The resource returns the following properties:

- **ProjectName** - The name of the project
- **VariableGroupName** - The name of the variable group
- **GroupName** - The name of the group
- **isInherited** - Whether permissions are inherited
- **Permissions** - The configured permissions
- **Ensure** - Current state ('Present' or 'Absent')

## Examples

### Example 1: Grant Variable Group Access to Team

```powershell
Configuration GrantVariableGroupAccess {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoVariableGroupPermission 'SharedVarsAccess' {
            ProjectName       = 'MyProject'
            VariableGroupName = 'SharedVariables'
            GroupName         = '[MyProject]\Development Team'
            isInherited       = $false
            Permissions       = @(
                @{
                    Identity   = '[MyProject]\Development Team'
                    Permission = @{ View = 'Allow'; Use = 'Allow' }
                }
            )
            Ensure            = 'Present'
        }
    }
}

GrantVariableGroupAccess
Start-DscConfiguration -Path ./GrantVariableGroupAccess -Wait -Verbose
```

### Example 2: Restrict Sensitive Variable Group

```powershell
Configuration RestrictSensitiveVariables {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoVariableGroupPermission 'AdminAccess' {
            ProjectName       = 'MyProject'
            VariableGroupName = 'Production Secrets'
            GroupName         = '[MyProject]\Project Admins'
            isInherited       = $false
            Permissions       = @(
                @{
                    Identity   = '[MyProject]\Project Admins'
                    Permission = @{
                        View       = 'Allow'
                        Use        = 'Allow'
                        Administer = 'Allow'
                        ViewSecrets = 'Allow'
                    }
                }
            )
            Ensure            = 'Present'
        }
        
        AzDoVariableGroupPermission 'DeveloperRestriction' {
            ProjectName       = 'MyProject'
            VariableGroupName = 'Production Secrets'
            GroupName         = '[MyProject]\Developers'
            isInherited       = $false
            Permissions       = @(
                @{
                    Identity   = '[MyProject]\Developers'
                    Permission = @{ Administer = 'Deny'; ViewSecrets = 'Deny' }
                }
            )
            Ensure            = 'Present'
        }
    }
}

RestrictSensitiveVariables
Start-DscConfiguration -Path ./RestrictSensitiveVariables -Wait -Verbose
```

### Example 3: Configure Multiple Variable Group Permissions

```powershell
Configuration MultiVariableGroupPermissions {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoVariableGroupPermission 'SharedVars' {
            ProjectName       = 'MyProject'
            VariableGroupName = 'Shared Variables'
            GroupName         = '[MyProject]\Development Team'
            isInherited       = $false
            Permissions       = @(
                @{
                    Identity   = '[MyProject]\Development Team'
                    Permission = @{ View = 'Allow'; Use = 'Allow' }
                }
            )
            Ensure            = 'Present'
        }
        
        AzDoVariableGroupPermission 'BuildVars' {
            ProjectName       = 'MyProject'
            VariableGroupName = 'Build Configuration'
            GroupName         = '[MyProject]\Build Admins'
            isInherited       = $false
            Permissions       = @(
                @{
                    Identity   = '[MyProject]\Build Admins'
                    Permission = @{ View = 'Allow'; Use = 'Allow'; Administer = 'Allow' }
                }
            )
            Ensure            = 'Present'
        }
        
        AzDoVariableGroupPermission 'DeployVars' {
            ProjectName       = 'MyProject'
            VariableGroupName = 'Deployment Settings'
            GroupName         = '[MyProject]\Release Team'
            isInherited       = $false
            Permissions       = @(
                @{
                    Identity   = '[MyProject]\Release Team'
                    Permission = @{ View = 'Allow'; Use = 'Allow' }
                }
            )
            Ensure            = 'Present'
        }
    }
}

MultiVariableGroupPermissions
Start-DscConfiguration -Path ./MultiVariableGroupPermissions -Wait -Verbose
```

### Example 4: Query Variable Group Permissions

```powershell
# Get the current state of variable group permissions
$properties = @{
    ProjectName       = 'MyProject'
    VariableGroupName = 'SharedVariables'
    GroupName         = 'Development Team'
}

$result = Invoke-DscResource -Name 'AzDoVariableGroupPermission' `
    -Method Get `
    -Property $properties `
    -ModuleName 'AzureDevOpsDscNative'

$result | Select-Object ProjectName, VariableGroupName, GroupName, isInherited, Permissions
```

### Example 5: Allow Pipeline Usage of Variable Group

```powershell
Configuration AllowPipelineUsage {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoVariableGroupPermission 'PipelineUsage' {
            ProjectName       = 'MyProject'
            VariableGroupName = 'Pipeline Variables'
            GroupName         = '[MyProject]\Pipeline Users'
            isInherited       = $false
            Permissions       = @(
                @{
                    Identity   = '[MyProject]\Pipeline Users'
                    Permission = @{ View = 'Allow'; Use = 'Allow' }
                }
            )
            Ensure            = 'Present'
        }
    }
}

AllowPipelineUsage
Start-DscConfiguration -Path ./AllowPipelineUsage -Wait -Verbose
```

## Important Notes

### Permission Bit Names

The Library (variable group) security namespace exposes these bit names (see [Permissions & ACLs](../Permissions.md#azdovariablegrouppermission) for the full table):

- **View** — View library item and its variables
- **Use** — Use the variable group in pipelines
- **Administer** — Administer library item (manage and delete; not recommended for broad groups)
- **Create** — Create new library items
- **ViewSecrets** — View secret variable values
- **Owner** — Owner-level access (not recommended for broad groups)

### Inheritance

- When `isInherited` is `$true`, permissions flow from project settings
- Setting `isInherited` to `$false` allows custom group-specific permissions
- Useful for restricting sensitive variable groups

### Best Practices

- Create separate variable groups for different environments (dev, staging, prod)
- Restrict edit and delete permissions to admins
- Use groups for variable group access rather than individual users
- Regularly audit who has access to sensitive variable groups
- Document variable group purposes

### Variable Group Access Control

- Different from variable permissions within a variable group
- Controls who can use and manage the group itself
- Essential for protecting sensitive data

## Troubleshooting

### Issue: "Variable Group Not Found"

**Cause**: The variable group does not exist

**Solution**:
```powershell
# Create the variable group first using AzDoVariableGroup resource
# Verify variable group name matches exactly (case-sensitive)
```

### Issue: "Cannot Set Permissions"

**Cause**: Group does not exist or insufficient permissions

**Solution**:
- Verify the group exists in the project
- Ensure user has variable group admin permissions
- Check personal access token has correct scope

### Issue: "Pipelines Cannot Use Variable Group"

**Cause**: Group lacks "Use" permission for pipeline users

**Solution**:
- Grant "Use" permission to pipeline service accounts or groups
- Verify pipelines have access to the variable group
- Check pipeline service connection permissions

## Related Resources

- [AzDoVariableGroup](AzDoVariableGroup) - Create and manage variable groups
- [AzDoProjectPermission](AzDoProjectPermission) - Manage project-level permissions
- [AzDoGroupPermission](AzDoGroupPermission) - Manage group permissions
- [AzDoPipeline](AzDoPipeline) - Create pipelines that use variable groups

## See Also

- [Azure DevOps Documentation](https://docs.microsoft.com/en-us/azure/devops/)
- [PowerShell DSC Documentation](https://docs.microsoft.com/en-us/powershell/dsc/overview)
- [AzureDevOpsDscNative Home](../Home)
