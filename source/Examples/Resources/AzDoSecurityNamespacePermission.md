# DSC AzDoSecurityNamespacePermission Resource

# Syntax

``` PowerShell
AzDoSecurityNamespacePermission [string] #ResourceName
{
    SecurityNamespace = [String]$SecurityNamespace
    Token             = [String]$Token
    GroupName         = [String]$GroupName
    [ isInherited     = [Boolean]$isInherited ]
    [ Permissions     = [HashTable[]]$Permissions ]
    [ Ensure          = [String] {'Present', 'Absent'} ]
}
```

# Common Properties

- __SecurityNamespace__: The name of the Azure DevOps security namespace (e.g., `Build`, `Git Repositories`, `Project`). This is a key property.
- __Token__: The security token identifying the specific object within the namespace. This is a key property.
- __GroupName__: The name of the group to grant permissions to. This is a key property. Use the format `[ProjectName]\GroupName`.
- __isInherited__: Whether permissions are inherited. Defaults to `$true`.
- __Permissions__: An array of permission hashtables specifying the permissions to grant or deny.
- __Ensure__: Specifies whether the permissions should exist. Valid values are `Present` and `Absent`. Defaults to `Present`.

## Permissions Syntax

``` PowerShell
AzDoSecurityNamespacePermission/Permissions
{
    Permission = [String]$PermissionName
    Access     = [String] {'Allow', 'Deny', 'NotSet'}
}
```

# Additional Information

This resource provides low-level access to Azure DevOps security namespaces, allowing fine-grained permission control over any object in the system. For most use cases, prefer the higher-level permission resources (e.g., `AzDoGitPermission`, `AzDoPipelinePermission`). Use this resource when you need to control permissions for namespaces not covered by dedicated resources.

Common security namespaces include:
- `Build` - Pipeline/build permissions
- `Git Repositories` - Git repository permissions
- `Project` - Project-level permissions
- `ReleaseManagement` - Release pipeline permissions
- `Library` - Variable group and secure file permissions

# Examples

## Example 1: Grant permissions in a security namespace

``` PowerShell
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoSecurityNamespacePermission 'AddNamespacePermission' {
            Ensure            = 'Present'
            SecurityNamespace = 'Build'
            Token             = 'repoV2/00000000-0000-0000-0000-000000000001'
            GroupName         = '[MyProject]\Contributors'
            isInherited       = $true
            Permissions       = @(
                @{ Permission = 'ViewBuilds'; Access = 'Allow' }
                @{ Permission = 'QueueBuilds'; Access = 'Allow' }
            )
        }
    }
}
```
