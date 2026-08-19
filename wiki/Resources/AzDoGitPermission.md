# AzDoGitPermission Resource

## Description

The `AzDoGitPermission` DSC resource is used to manage Git repository permissions (Git Repositories security namespace ACEs) within an Azure DevOps project. It allows you to define and enforce the desired state of permissions assigned to identities for a repository (or, when `RepositoryName` is left unset, at the project's repository root), including whether permissions are inherited.

> **Verified against source:** `source/Classes/041.AzDoGitPermission.ps1`.

## Syntax

```powershell
AzDoGitPermission [string] #ResourceName
{
    ProjectName = [String] $ProjectName
    [ RepositoryName = [String] $RepositoryName ]
    [ isInherited = [Boolean] $isInherited ]
    [ Permissions = [Hashtable[]] $Permissions ]
    [ Ensure = [String] {'Present', 'Absent'} ]
    [ DependsOn = [String[]] ]
    [ PsDscRunAsCredential = [PSCredential] ]
}
```

## Properties

### Key Properties (Required)

- **ProjectName** [String] - The name of the Azure DevOps project. Aliased as `Name`.

### Optional Properties

- **RepositoryName** [String] - The name of the Git repository within the project. If not specified (`$null`, the default), permissions apply at the project's repository-root token. Aliased as `Repository`.

- **isInherited** [Boolean] - Specifies whether the permissions are inherited from the parent project/repository scope. Default is `$true`.

- **Permissions** [Hashtable[]] - An array of ACE hashtables. Each entry has:
  - `Identity` - The identity/group the ACE applies to, e.g. `'[ProjectName]\GroupName'`
  - `Permission` - A hashtable mapping Git permission bit names to `'Allow'` or `'Deny'`, e.g. `@{ GenericRead = 'Allow'; GenericContribute = 'Allow' }`

- **Ensure** [String] - Desired state of the resource:
  - `'Present'` - (default) Repository permissions should exist
  - `'Absent'` - Repository permissions should be removed

### Common Properties

- **DependsOn** [String[]] - Dependencies on other resources.

- **PsDscRunAsCredential** [PSCredential] - Credentials to run this resource under.

## Return Values

- **ProjectName** - The name of the project
- **RepositoryName** - The name of the repository (if specified)
- **isInherited** - Whether permissions are inherited
- **Permissions** - The current Git permissions assigned
- **Ensure** - Current state ('Present' or 'Absent')

## Examples

### Example 1: Grant Read/Contribute Access to a Group

```powershell
Configuration ConfigureRepositoryContribute {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    Node localhost {
        AzDoGitPermission 'MainRepoContribute' {
            ProjectName     = 'MyProject'
            RepositoryName  = 'MainRepository'
            isInherited     = $false
            Permissions     = @(
                @{
                    Identity   = '[MyProject]\Group1'
                    Permission = @{
                        GenericRead       = 'Allow'
                        GenericContribute = 'Allow'
                    }
                }
            )
            Ensure          = 'Present'
        }
    }
}

ConfigureRepositoryContribute
Start-DscConfiguration -Path ./ConfigureRepositoryContribute -Wait -Verbose
```

### Example 2: Grant One Group Access, Deny Another

```powershell
Configuration ConfigureAdvancedRepositoryPermissions {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    Node localhost {
        AzDoGitPermission 'DevelopmentRepoAdvanced' {
            ProjectName     = 'MyProject'
            RepositoryName  = 'DevelopmentRepository'
            isInherited     = $false
            Permissions     = @(
                @{
                    Identity   = '[MyProject]\Group1'
                    Permission = @{
                        GenericRead       = 'Allow'
                        GenericContribute = 'Allow'
                    }
                },
                @{
                    Identity   = '[MyProject]\Group2'
                    Permission = @{
                        GenericRead       = 'Deny'
                        GenericContribute = 'Deny'
                    }
                }
            )
            Ensure          = 'Present'
        }
    }
}

ConfigureAdvancedRepositoryPermissions
Start-DscConfiguration -Path ./ConfigureAdvancedRepositoryPermissions -Wait -Verbose
```

### Example 3: Broader Set of ACEs (Branch Management, Policies, Locks)

Modeled on the real Git-permission ACEs used in the companion `Dsc.PipelineRunner` project's example configuration:

```powershell
Configuration GitPermissionsExample {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    Node localhost {
        AzDoGitPermission 'ConfigurationGitPermissions' {
            ProjectName    = 'MyProject'
            RepositoryName = 'CON_Configuration'
            isInherited    = $false
            Permissions    = @(
                @{
                    Identity   = '[MyProject]\Readers'
                    Permission = @{ Read = 'Allow' }
                },
                @{
                    Identity   = '[MyProject]\Contributors'
                    Permission = @{
                        Read                  = 'Allow'
                        Contribute            = 'Allow'
                        CreateBranch          = 'Allow'
                        PullRequestContribute = 'Allow'
                    }
                },
                @{
                    Identity   = '[MyProject]\ReleaseAdministrators'
                    Permission = @{
                        Read                  = 'Allow'
                        CreateTag             = 'Allow'
                        ManageNote            = 'Allow'
                        EditPolicies          = 'Allow'
                        PullRequestContribute = 'Allow'
                    }
                }
            )
            Ensure         = 'Present'
        }
    }
}

GitPermissionsExample
Start-DscConfiguration -Path ./GitPermissionsExample -Wait -Verbose
```

### Example 4: Query and Set via Invoke-DscResource

```powershell
$properties = @{
    ProjectName    = 'MyProject'
    RepositoryName = 'MainRepository'
}

$result = Invoke-DscResource -Name 'AzDoGitPermission' `
    -Method Get `
    -Property $properties `
    -ModuleName 'AzureDevOpsDscNative'

$result | Select-Object ProjectName, RepositoryName, isInherited, Permissions

$setProperties = @{
    ProjectName    = 'MyProject'
    RepositoryName = 'MainRepository'
    isInherited    = $false
    Permissions    = @(
        @{ Identity = '[MyProject]\Group1'; Permission = @{ GenericRead = 'Allow'; GenericContribute = 'Allow' } }
    )
    Ensure         = 'Present'
}

Invoke-DscResource -Name 'AzDoGitPermission' `
    -Method Set `
    -Property $setProperties `
    -ModuleName 'AzureDevOpsDscNative'
```

## Important Notes

### Repository Scope

- When `RepositoryName` is not specified (`$null`), permissions apply at the repository-root token for the project.
- When `RepositoryName` is specified, permissions apply only to that specific repository's token.

### Git Permission Bit Names

Bit names inside `Permission` are Git Repositories security-namespace ActionNames. Names confirmed in this module's own integration tests and the companion LCM project's example configuration include: `GenericRead`, `GenericContribute`, `Read`, `Contribute`, `CreateBranch`, `CreateTag`, `PullRequestContribute`, `ManageNote`, `EditPolicies`, `RemoveOthersLocks`, `ManagePermissions`. The full, authoritative list for your organization can always be retrieved live — see [Permissions](../Permissions.md).

### Inheritance Behavior

- Permissions set at the project (repository-root) level cascade to all repositories unless `isInherited = $false` is set on a repository-specific entry.

## Troubleshooting

### Issue: "Repository Not Found"

**Cause**: The specified repository name does not exist in the project.

**Solution**: Verify the repository name exists (case-sensitive) — check the Azure DevOps Repos section, or create it first with [AzDoGitRepository](AzDoGitRepository.md).

### Issue: "Cannot Set Permissions"

**Cause**: Insufficient permissions or invalid group identity.

**Solution**: Verify user has project administrator permissions, that the group exists, and that the token has sufficient scope.

## Related Resources

- [AzDoGitRepository](AzDoGitRepository.md) - Create and manage Git repositories
- [AzDoProjectPermission](AzDoProjectPermission.md) - Manage project-level permissions
- [AzDoProjectGroup](AzDoProjectGroup.md) - Manage project groups and their membership
- [AzDoSecurityNamespacePermission](AzDoSecurityNamespacePermission.md) - Manage custom security namespace permissions
- [Permissions overview](../Permissions.md) - Conceptual guide to permission resources

## See Also

- [Azure DevOps Git Repository Permissions](https://docs.microsoft.com/en-us/azure/devops/repos/git/repository-permissions)
- [Azure DevOps Security Namespaces Documentation](https://docs.microsoft.com/en-us/azure/devops/organizations/security/namespace-reference)
- [PowerShell DSC Documentation](https://docs.microsoft.com/en-us/powershell/dsc/overview)
- [AzureDevOpsDscNative Home](../Home.md)
