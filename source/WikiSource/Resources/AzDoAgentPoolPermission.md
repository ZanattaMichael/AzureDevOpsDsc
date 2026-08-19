# AzDoAgentPoolPermission Resource

## Description

The `AzDoAgentPoolPermission` DSC resource is used to manage role-based permissions for agent pools at the organization level in Azure DevOps. It allows you to control which groups and users can manage, use, or edit agent pools, ensuring that critical build infrastructure is protected and accessible only to authorized personnel.

## Syntax

```powershell
AzDoAgentPoolPermission [string] #ResourceName
{
    PoolName = [String] $PoolName
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

- **PoolName** [String] - The name of the agent pool at the organization level.

- **GroupName** [String] - The name of the group whose permissions are being managed.

### Optional Properties

- **isInherited** [Boolean] - Whether permissions are inherited from organization level defaults. Default is `$true`.

- **Permissions** [HashTable[]] - An array of ACE hashtables. Each entry has:
  - `Identity` - The group or user identity, e.g. `'[MyOrganization]\GroupName'` (conventionally matching `GroupName` above)
  - `Permission` - A hashtable mapping Agent Pool security-namespace bit names to `'Allow'` or `'Deny'`, e.g. `@{ Use = 'Allow'; ViewAuthorization = 'Allow' }`

  See [Permissions & ACLs](../Permissions.md#azdoagentpoolpermission) for the full list of valid bit names (`Use`, `Manage`, `Create`, `ViewAuthorization`, `ManagePermissions`).

- **Ensure** [String] - Desired state of the resource:
  - `'Present'` - (default) Permissions should be configured
  - `'Absent'` - Permissions should be removed

### Common Properties

- **DependsOn** [String[]] - Dependencies on other resources. Use this to control the order of resource execution.

- **PsDscRunAsCredential** [PSCredential] - Credentials to run this resource under.

## Return Values

The resource returns the following properties:

- **PoolName** - The name of the agent pool
- **GroupName** - The name of the group
- **isInherited** - Whether permissions are inherited
- **Permissions** - The configured permissions
- **Ensure** - Current state ('Present' or 'Absent')

## Examples

### Example 1: Grant Agent Pool Access

```powershell
Configuration GrantAgentPoolAccess {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoAgentPoolPermission 'BuildPoolAccess' {
            PoolName    = 'Build Agents'
            GroupName   = '[MyOrganization]\Build Team'
            isInherited = $false
            Permissions = @(
                @{
                    Identity   = '[MyOrganization]\Build Team'
                    Permission = @{
                        Use              = 'Allow'
                        ViewAuthorization = 'Allow'
                    }
                }
            )
            Ensure      = 'Present'
        }
    }
}

GrantAgentPoolAccess
Start-DscConfiguration -Path ./GrantAgentPoolAccess -Wait -Verbose
```

### Example 2: Restrict Production Agent Pool

```powershell
Configuration RestrictProductionPool {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoAgentPoolPermission 'ProdAdminAccess' {
            PoolName    = 'Production Agents'
            GroupName   = '[MyOrganization]\DevOps Admins'
            isInherited = $false
            Permissions = @(
                @{
                    Identity   = '[MyOrganization]\DevOps Admins'
                    Permission = @{
                        Use               = 'Allow'
                        Manage            = 'Allow'
                        ViewAuthorization = 'Allow'
                    }
                }
            )
            Ensure      = 'Present'
        }
        
        AzDoAgentPoolPermission 'DeveloperRestriction' {
            PoolName    = 'Production Agents'
            GroupName   = '[MyOrganization]\Developers'
            isInherited = $false
            Permissions = @(
                @{
                    Identity   = '[MyOrganization]\Developers'
                    Permission = @{ Use = 'Deny' }
                }
            )
            Ensure      = 'Present'
        }
    }
}

RestrictProductionPool
Start-DscConfiguration -Path ./RestrictProductionPool -Wait -Verbose
```

### Example 3: Configure Multiple Pool Permissions

```powershell
Configuration MultiPoolPermissions {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoAgentPoolPermission 'BuildPool' {
            PoolName    = 'Linux Build Agents'
            GroupName   = '[MyOrganization]\Build Team'
            isInherited = $false
            Permissions = @(
                @{
                    Identity   = '[MyOrganization]\Build Team'
                    Permission = @{ Use = 'Allow'; ViewAuthorization = 'Allow' }
                }
            )
            Ensure      = 'Present'
        }
        
        AzDoAgentPoolPermission 'TestPool' {
            PoolName    = 'Windows Test Agents'
            GroupName   = '[MyOrganization]\QA Team'
            isInherited = $false
            Permissions = @(
                @{
                    Identity   = '[MyOrganization]\QA Team'
                    Permission = @{ Use = 'Allow'; ViewAuthorization = 'Allow' }
                }
            )
            Ensure      = 'Present'
        }
        
        AzDoAgentPoolPermission 'DeployPool' {
            PoolName    = 'Production Deployment Agents'
            GroupName   = '[MyOrganization]\DevOps Team'
            isInherited = $false
            Permissions = @(
                @{
                    Identity   = '[MyOrganization]\DevOps Team'
                    Permission = @{ Use = 'Allow'; Manage = 'Allow'; ViewAuthorization = 'Allow' }
                }
            )
            Ensure      = 'Present'
        }
    }
}

MultiPoolPermissions
Start-DscConfiguration -Path ./MultiPoolPermissions -Wait -Verbose
```

### Example 4: Query Agent Pool Permissions

```powershell
# Get the current state of agent pool permissions
$properties = @{
    PoolName  = 'Build Agents'
    GroupName = 'Build Team'
}

$result = Invoke-DscResource -Name 'AzDoAgentPoolPermission' `
    -Method Get `
    -Property $properties `
    -ModuleName 'AzureDevOpsDscNative'

$result | Select-Object PoolName, GroupName, isInherited, Permissions
```

### Example 5: Grant Pool Management Rights

```powershell
Configuration GrantPoolManagement {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoAgentPoolPermission 'PoolManagement' {
            PoolName    = 'Shared Agent Pool'
            GroupName   = '[MyOrganization]\Infrastructure Team'
            isInherited = $false
            Permissions = @(
                @{
                    Identity   = '[MyOrganization]\Infrastructure Team'
                    Permission = @{
                        Use               = 'Allow'
                        Manage            = 'Allow'
                        Create            = 'Allow'
                        ViewAuthorization = 'Allow'
                        ManagePermissions = 'Allow'
                    }
                }
            )
            Ensure      = 'Present'
        }
    }
}

GrantPoolManagement
Start-DscConfiguration -Path ./GrantPoolManagement -Wait -Verbose
```

### Example 6: Disable Permission Inheritance

```powershell
Configuration CustomPoolPermissions {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoAgentPoolPermission 'CustomPermissions' {
            PoolName    = 'Special Use Pool'
            GroupName   = '[MyOrganization]\Specialized Team'
            isInherited = $false
            Permissions = @(
                @{
                    Identity   = '[MyOrganization]\Specialized Team'
                    Permission = @{ Use = 'Allow'; ViewAuthorization = 'Allow' }
                }
            )
            Ensure      = 'Present'
        }
    }
}

CustomPoolPermissions
Start-DscConfiguration -Path ./CustomPoolPermissions -Wait -Verbose
```

## Important Notes

### Permission Bit Names

The Agent Pool security namespace exposes these bit names (see [Permissions & ACLs](../Permissions.md#azdoagentpoolpermission) for the full table):

- **Use** — Use the pool in project queues/pipelines
- **Manage** — Manage agents and pool settings (not recommended for broad groups)
- **Create** — Create new agent pools
- **ViewAuthorization** — View pool authorization settings
- **ManagePermissions** — Administer pool permissions (not recommended for broad groups)

### Organization-Level Resource

- Agent pool permissions are managed at organization level
- Different from project-level queue permissions
- Controls access to the pool infrastructure itself

### Best Practices

- Restrict edit and delete permissions to DevOps/Infrastructure teams
- Grant "Use" permission broadly to projects that need the pool
- Create separate pools for different workload types
- Document pool purposes and access requirements
- Regularly audit pool permissions

### Inheritance and Custom Permissions

- Use inherited permissions for standard access patterns
- Set `isInherited = $false` for specialized pools
- Custom permissions override inherited defaults

## Troubleshooting

### Issue: "Agent Pool Not Found"

**Cause**: The agent pool does not exist

**Solution**:
```powershell
# Create the agent pool first using AzDoAgentPool resource
# Verify pool name matches exactly
```

### Issue: "Cannot Set Pool Permissions"

**Cause**: Group does not exist or insufficient permissions

**Solution**:
- Verify the group exists (typically organization-level groups)
- Ensure user has organization administrator permissions
- Check personal access token has "Agent Pools (read & manage)" scope

### Issue: "Projects Cannot Access Pool via Queue"

**Cause**: Queue permissions independent from pool permissions

**Solution**:
- Grant "Use" permission at pool level
- Create project queue linked to the pool
- Configure project queue permissions separately

## Related Resources

- [AzDoAgentPool](AzDoAgentPool) - Create and manage agent pools
- [AzDoAgentQueue](AzDoAgentQueue) - Create agent queues in projects
- [AzDoProjectPermission](AzDoProjectPermission) - Manage project-level permissions
- [AzDoGroupPermission](AzDoGroupPermission) - Manage group permissions

## See Also

- [Azure DevOps Documentation](https://docs.microsoft.com/en-us/azure/devops/)
- [PowerShell DSC Documentation](https://docs.microsoft.com/en-us/powershell/dsc/overview)
- [AzureDevOpsDscNative Home](../Home)
