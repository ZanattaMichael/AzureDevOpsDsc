# AzDoEnvironmentPermission Resource

## Description

The `AzDoEnvironmentPermission` DSC resource is used to manage permissions on deployment environments within an Azure DevOps project. Deployment environments are used in pipelines to define deployment targets with approval requirements and checks. This resource allows you to configure and enforce the desired state of permissions assigned to groups for specific environments, controlling who can deploy to and administer these environments.

## Syntax

```powershell
AzDoEnvironmentPermission [string] #ResourceName
{
    ProjectName = [String] $ProjectName
    EnvironmentName = [String] $EnvironmentName
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

- **ProjectName** [String] - The name of the Azure DevOps project containing the environment.

### Mandatory Properties

- **EnvironmentName** [String] - The name of the deployment environment for which permissions are being configured. Environments define deployment targets and can have approvals and checks.

- **GroupName** [String] - The name of the group to which permissions are assigned. The group must exist in the project or organization.

### Optional Properties

- **isInherited** [Boolean] - Specifies whether the permissions are inherited from the project level. Default is `$true`. When set to `$false`, only explicitly assigned permissions apply.

- **Permissions** [Hashtable[]] - An array of ACE hashtables. Each entry has:
  - `Identity` - The group or user identity, e.g. `'[ProjectName]\GroupName'` (conventionally matching `GroupName` above)
  - `Permission` - A hashtable mapping Environment security-namespace bit names to `'Allow'` or `'Deny'`, e.g. `@{ View = 'Allow'; Use = 'Allow' }`

  See [Permissions & ACLs](../Permissions.md#azdoenvironmentpermission) for the full list of valid bit names (`View`, `Manage`, `Use`, `Administer`).

- **Ensure** [String] - Desired state of the resource:
  - `'Present'` - (default) Environment permissions should exist
  - `'Absent'` - Environment permissions should be removed

### Common Properties

- **DependsOn** [String[]] - Dependencies on other resources. Use this to control the order of resource execution.

- **PsDscRunAsCredential** [PSCredential] - Credentials to run this resource under.

## Return Values

The resource returns the following properties:

- **ProjectName** - The name of the project
- **EnvironmentName** - The name of the environment
- **GroupName** - The name of the group
- **isInherited** - Whether permissions are inherited
- **Permissions** - The current environment permissions assigned
- **Ensure** - Current state ('Present' or 'Absent')

## Examples

### Example 1: Grant Deployment Access to Development Environment

```powershell
Configuration GrantDevEnvironmentAccess {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoEnvironmentPermission 'DevelopersDevEnv' {
            ProjectName     = 'MyProject'
            EnvironmentName = 'Development'
            GroupName       = '[MyProject]\Developers'
            isInherited     = $false
            Permissions     = @(
                @{
                    Identity   = '[MyProject]\Developers'
                    Permission = @{ View = 'Allow'; Use = 'Allow' }
                }
            )
            Ensure = 'Present'
        }
    }
}

GrantDevEnvironmentAccess
Start-DscConfiguration -Path ./GrantDevEnvironmentAccess -Wait -Verbose
```

### Example 2: Configure Administrative Access to Production Environment

```powershell
Configuration GrantProdEnvironmentAdmin {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoEnvironmentPermission 'AdminsProdEnv' {
            ProjectName     = 'MyProject'
            EnvironmentName = 'Production'
            GroupName       = '[MyProject]\Release Administrators'
            isInherited     = $false
            Permissions     = @(
                @{
                    Identity   = '[MyProject]\Release Administrators'
                    Permission = @{ View = 'Allow'; Use = 'Allow'; Manage = 'Allow' }
                }
            )
            Ensure = 'Present'
        }
    }
}

GrantProdEnvironmentAdmin
Start-DscConfiguration -Path ./GrantProdEnvironmentAdmin -Wait -Verbose
```

### Example 3: Configure Multiple Environments with Tiered Access

```powershell
Configuration ConfigureEnvironmentHierarchy {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        # Development environment - All developers can deploy
        AzDoEnvironmentPermission 'DevelopersDevEnv' {
            ProjectName     = 'MyProject'
            EnvironmentName = 'Development'
            GroupName       = '[MyProject]\Developers'
            isInherited     = $false
            Permissions     = @(
                @{
                    Identity   = '[MyProject]\Developers'
                    Permission = @{ View = 'Allow'; Use = 'Allow' }
                }
            )
            Ensure = 'Present'
        }
        
        # Staging environment - QA can deploy
        AzDoEnvironmentPermission 'QAStagingEnv' {
            ProjectName     = 'MyProject'
            EnvironmentName = 'Staging'
            GroupName       = '[MyProject]\Quality Assurance'
            isInherited     = $false
            Permissions     = @(
                @{
                    Identity   = '[MyProject]\Quality Assurance'
                    Permission = @{ View = 'Allow'; Use = 'Allow' }
                }
            )
            Ensure = 'Present'
        }
        
        # Production environment - Only Release team can deploy
        AzDoEnvironmentPermission 'ReleaseProdEnv' {
            ProjectName     = 'MyProject'
            EnvironmentName = 'Production'
            GroupName       = '[MyProject]\Release Team'
            isInherited     = $false
            Permissions     = @(
                @{
                    Identity   = '[MyProject]\Release Team'
                    Permission = @{ View = 'Allow'; Use = 'Allow' }
                }
            )
            Ensure = 'Present'
        }
        
        # Production environment admin - Release admins manage approvals/checks
        AzDoEnvironmentPermission 'AdminProdEnv' {
            ProjectName     = 'MyProject'
            EnvironmentName = 'Production'
            GroupName       = '[MyProject]\Release Administrators'
            isInherited     = $false
            Permissions     = @(
                @{
                    Identity   = '[MyProject]\Release Administrators'
                    Permission = @{ View = 'Allow'; Use = 'Allow'; Manage = 'Allow' }
                }
            )
            Ensure = 'Present'
        }
    }
}

ConfigureEnvironmentHierarchy
Start-DscConfiguration -Path ./ConfigureEnvironmentHierarchy -Wait -Verbose
```

### Example 4: Restrict Environment Access to Specific Teams

```powershell
Configuration RestrictEnvironmentAccess {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        # Deny deployment access to Developers on Production
        AzDoEnvironmentPermission 'RestrictProdEnv' {
            ProjectName     = 'MyProject'
            EnvironmentName = 'Production'
            GroupName       = '[MyProject]\Developers'
            isInherited     = $false
            Permissions     = @(
                @{
                    Identity   = '[MyProject]\Developers'
                    Permission = @{ Use = 'Deny'; Manage = 'Deny' }
                }
            )
            Ensure = 'Present'
        }
    }
}

RestrictEnvironmentAccess
Start-DscConfiguration -Path ./RestrictEnvironmentAccess -Wait -Verbose
```

### Example 5: Using Invoke-DscResource to Manage Environment Permissions

```powershell
# Get current environment permissions
$properties = @{
    ProjectName     = 'MyProject'
    EnvironmentName = 'Production'
    GroupName       = '[MyProject]\Release Team'
}

$result = Invoke-DscResource -Name 'AzDoEnvironmentPermission' `
    -Method Get `
    -Property $properties `
    -ModuleName 'AzureDevOpsDscNative'

$result | Select-Object ProjectName, EnvironmentName, GroupName, isInherited, Permissions

# Set new environment permissions
$setProperties = @{
    ProjectName     = 'MyProject'
    EnvironmentName = 'Production'
    GroupName       = '[MyProject]\Release Team'
    isInherited     = $false
    Permissions     = @(
        @{
            Identity   = '[MyProject]\Release Team'
            Permission = @{ View = 'Allow'; Use = 'Allow' }
        }
    )
    Ensure = 'Present'
}

Invoke-DscResource -Name 'AzDoEnvironmentPermission' `
    -Method Set `
    -Property $setProperties `
    -ModuleName 'AzureDevOpsDscNative'
```

## Important Notes

### Permission Bit Names

The Environment security namespace exposes these bit names (see [Permissions & ACLs](../Permissions.md#azdoenvironmentpermission) for the full table):

- **View** — View environment details
- **Use** — Use the environment in pipeline deployments
- **Manage** — Manage approvals, checks, and settings on the environment
- **Administer** — Administer environment permissions (grant sparingly)

### Environment Types

- **Development** - Often allows broad access; used for testing and experimental deployments
- **Staging/QA** - Restricted access; used for quality assurance and validation
- **Production** - Highly restricted access; typically requires approvals and checks

### Approvals and Checks

- Environments can have manual approvals required before deployment
- Checks can validate conditions before allowing deployment
- Admin permissions allow configuration of these controls
- Approval and check settings complement permission settings

### Deployment Pipeline Integration

- Pipelines reference environments by name
- Pipeline users need at least "User" permission to deploy to an environment
- Multiple approval groups can be configured for sensitive environments
- Parallel approvals can speed up deployment processes

### Inheritance Behavior

- When `isInherited` is `$true`, groups inherit permissions from project level
- When `isInherited` is `$false`, only explicitly defined permissions apply
- Production environments should carefully control inheritance
- Most organizations set `isInherited = $false` for production environments

## Troubleshooting

### Issue: "Environment Not Found"

**Cause**: The specified environment does not exist in the project.

**Solution**:
```powershell
# Verify the environment exists in the project
# Check Pipelines -> Environments section
# Ensure the exact environment name is used (case-sensitive)
# Create the environment first if it doesn't exist
```

### Issue: "Group Cannot Deploy to Environment"

**Cause**: The group does not have "User" permission on the environment.

**Solution**:
```powershell
# Grant "User" permission to the appropriate group
# Check pipeline definitions for environment references
# Verify the group exists and is valid
# Confirm pipeline execution identity has permission
```

### Issue: "Cannot Manage Environment Approvals"

**Cause**: The group does not have "Admin" permission on the environment.

**Solution**:
```powershell
# Grant "Admin" permission to groups that manage approvals
# Verify the user making configuration changes has Admin permission
# Check project administrator permissions
```

### Issue: "Approval Conditions Not Enforced"

**Cause**: User has Admin permission but checks/approvals not properly configured.

**Solution**:
```powershell
# Configure approvals and checks separately in environment settings
# Ensure environment is properly referenced in pipeline
# Verify pipeline is using the environment correctly
# Check for inherited permissions overriding specific settings
```

## Related Resources

- [AzDoPipelineEnvironment](AzDoPipelineEnvironment) - Create and manage deployment environments
- [AzDoEnvironmentApproval](AzDoEnvironmentApproval) - Configure approvals for environments
- [AzDoPipeline](AzDoPipeline) - Create pipelines that deploy to environments
- [AzDoProjectPermission](AzDoProjectPermission) - Manage project-level permissions
- [AzDoProjectGroup](AzDoProjectGroup) - Manage project groups

## See Also

- [Azure DevOps Deployment Environments](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/environments)
- [Azure DevOps Environment Approvals and Checks](https://docs.microsoft.com/en-us/azure/devops/pipelines/process/approvals)
- [Azure DevOps Security Namespaces Documentation](https://docs.microsoft.com/en-us/azure/devops/organizations/security/namespace-reference)
- [PowerShell DSC Documentation](https://docs.microsoft.com/en-us/powershell/dsc/overview)
- [AzureDevOpsDscNative Home](../Home)
