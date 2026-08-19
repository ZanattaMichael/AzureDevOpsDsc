# AzDoSecurityNamespacePermission Resource

## Description

The `AzDoSecurityNamespacePermission` DSC resource is used to manage granular permissions within Azure DevOps security namespaces. It allows advanced users and administrators to configure fine-grained access control for specific Azure DevOps resources and operations using the underlying security token system, providing flexibility for complex permission scenarios that standard resource permissions don't cover.

## Syntax

```powershell
AzDoSecurityNamespacePermission [string] #ResourceName
{
    SecurityNamespace = [String] $SecurityNamespace
    Token = [String] $Token
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

- **SecurityNamespace** [String] - The identifier of the security namespace (e.g., 'Build', 'Release', 'Git Repositories').

- **Token** [String] - The security token that identifies the specific resource within the namespace.

- **GroupName** [String] - The name of the group whose permissions are being managed.

### Optional Properties

- **isInherited** [Boolean] - Whether permissions are inherited. Default is `$true`.

- **Permissions** [HashTable[]] - An array of ACE hashtables. Each entry has:
  - `Identity` - The group or user identity, e.g. `'[ProjectName]\GroupName'` (conventionally matching `GroupName` above)
  - `Permission` - A hashtable mapping the target namespace's bit names to `'Allow'` or `'Deny'`

  Bit names depend on which `SecurityNamespace` you target. See the Azure DevOps Security Namespace Reference and [Permissions & ACLs](../Permissions.md#azdosecuritynamespacepermission) for guidance.

- **Ensure** [String] - Desired state of the resource:
  - `'Present'` - (default) Permissions should be configured
  - `'Absent'` - Permissions should be removed

### Common Properties

- **DependsOn** [String[]] - Dependencies on other resources. Use this to control the order of resource execution.

- **PsDscRunAsCredential** [PSCredential] - Credentials to run this resource under.

## Return Values

The resource returns the following properties:

- **SecurityNamespace** - The security namespace identifier
- **Token** - The security token
- **GroupName** - The group name
- **isInherited** - Whether permissions are inherited
- **Permissions** - The configured permissions
- **Ensure** - Current state ('Present' or 'Absent')

## Examples

### Example 1: Configure Generic Namespace Permissions

```powershell
Configuration NamespacePermissions {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoSecurityNamespacePermission 'BuildPermissions' {
            SecurityNamespace = 'Build'
            Token             = 'ProjectToken'
            GroupName         = '[MyProject]\Developers'
            isInherited       = $false
            Permissions       = @(
                @{
                    Identity   = '[MyProject]\Developers'
                    Permission = @{ ViewBuilds = 'Allow'; QueueBuilds = 'Allow' }
                }
            )
            Ensure            = 'Present'
        }
    }
}

NamespacePermissions
Start-DscConfiguration -Path ./NamespacePermissions -Wait -Verbose
```

### Example 2: Advanced Permission Configuration

```powershell
Configuration AdvancedPermissions {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        # Token format varies per namespace — consult the Azure DevOps Security Namespace Reference
        AzDoSecurityNamespacePermission 'AnalyticsPermissions' {
            SecurityNamespace = 'AnalyticsViews'
            Token             = '$/'
            GroupName         = '[MyProject]\Release Team'
            isInherited       = $false
            Permissions       = @(
                @{
                    Identity   = '[MyProject]\Release Team'
                    Permission = @{ Read = 'Allow'; Execute = 'Allow' }
                }
            )
            Ensure            = 'Present'
        }
    }
}

AdvancedPermissions
Start-DscConfiguration -Path ./AdvancedPermissions -Wait -Verbose
```

### Example 3: Restrict Access via Namespace

```powershell
Configuration RestrictNamespaceAccess {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoSecurityNamespacePermission 'AdminAccess' {
            SecurityNamespace = 'AnalyticsViews'
            Token             = '$/'
            GroupName         = '[MyProject]\Project Admins'
            isInherited       = $false
            Permissions       = @(
                @{
                    Identity   = '[MyProject]\Project Admins'
                    Permission = @{ Read = 'Allow'; Execute = 'Allow'; Delete = 'Allow' }
                }
            )
            Ensure            = 'Present'
        }
        
        AzDoSecurityNamespacePermission 'UserRestriction' {
            SecurityNamespace = 'AnalyticsViews'
            Token             = '$/'
            GroupName         = '[MyProject]\Developers'
            isInherited       = $false
            Permissions       = @(
                @{
                    Identity   = '[MyProject]\Developers'
                    Permission = @{ Delete = 'Deny' }
                }
            )
            Ensure            = 'Present'
        }
    }
}

RestrictNamespaceAccess
Start-DscConfiguration -Path ./RestrictNamespaceAccess -Wait -Verbose
```

### Example 4: Query Namespace Permissions

```powershell
# Get the current state of namespace permissions
$properties = @{
    SecurityNamespace = 'Build'
    Token            = 'ProjectToken'
    GroupName        = 'Developers'
}

$result = Invoke-DscResource -Name 'AzDoSecurityNamespacePermission' `
    -Method Get `
    -Property $properties `
    -ModuleName 'AzureDevOpsDscNative'

$result | Select-Object SecurityNamespace, Token, GroupName, isInherited, Permissions
```

### Example 5: Multiple Namespace Configurations

```powershell
Configuration MultiNamespaceConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        # Prefer dedicated resources (AzDoGitPermission, AzDoIterationPermission)
        # when one exists. Use AzDoSecurityNamespacePermission for namespaces
        # that have no dedicated resource.
        AzDoSecurityNamespacePermission 'GitNamespace' {
            SecurityNamespace = 'Git Repositories'
            Token             = 'repoV2/<ProjectId>/<RepoId>'
            GroupName         = '[MyProject]\Developers'
            isInherited       = $false
            Permissions       = @(
                @{
                    Identity   = '[MyProject]\Developers'
                    Permission = @{ GenericRead = 'Allow'; GenericContribute = 'Allow' }
                }
            )
            Ensure            = 'Present'
        }
    }
}

MultiNamespaceConfig
Start-DscConfiguration -Path ./MultiNamespaceConfig -Wait -Verbose
```

## Important Notes

### Security Namespaces

- Namespaces represent categories of securable objects (Build, Release, Git, etc.)
- Each namespace has specific permissions (Read, Write, Edit, Delete, etc.)
- Token identifies the specific resource within the namespace

### Advanced Feature

- This is an advanced resource for complex permission scenarios
- Use standard permission resources (AzDoPipelinePermission, etc.) when available
- Requires understanding of Azure DevOps security model

### Tokens

- Tokens are hierarchical identifiers for resources
- Format varies by namespace type
- Examples: project tokens, repository tokens, pipeline definition tokens

### Best Practices

- Use specific resource permission resources when available
- Document namespace and token usage for maintainability
- Test permission changes in non-production first
- Regularly audit namespace-level permissions

## Troubleshooting

### Issue: "Invalid Security Namespace"

**Cause**: Namespace name is incorrect or doesn't exist

**Solution**:
```powershell
# Verify namespace name matches Azure DevOps security model
# Common namespaces: Build, Release, Git Repositories, Iteration, etc.
```

### Issue: "Invalid Token Format"

**Cause**: Token format doesn't match the namespace type

**Solution**:
- Research token format for specific namespace
- Tokens vary by namespace type and resource
- Consult Azure DevOps security documentation

### Issue: "Cannot Set Namespace Permissions"

**Cause**: Insufficient permissions or invalid group

**Solution**:
- Verify user has namespace administrator permissions
- Check group exists at appropriate level
- Ensure personal access token has sufficient scope

## Related Resources

- [AzDoPipelinePermission](AzDoPipelinePermission.md) - Manage pipeline permissions
- [AzDoGitPermission](AzDoGitPermission.md) - Manage repository permissions
- [AzDoAreaPermission](AzDoAreaPermission.md) - Manage area permissions
- [AzDoGroupPermission](AzDoGroupPermission.md) - Manage group permissions

## See Also

- [Azure DevOps Documentation](https://docs.microsoft.com/en-us/azure/devops/)
- [PowerShell DSC Documentation](https://docs.microsoft.com/en-us/powershell/dsc/overview)
- [AzureDevOpsDscNative Home](../Home.md)
