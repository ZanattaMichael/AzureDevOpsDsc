# DSC AzDoEnvironmentPermission Resource

# Syntax

``` PowerShell
AzDoEnvironmentPermission [string] #ResourceName
{
    ProjectName     = [String]$ProjectName
    EnvironmentName = [String]$EnvironmentName
    GroupName       = [String]$GroupName
    [ isInherited   = [Boolean]$isInherited ]
    [ Permissions   = [HashTable[]]$Permissions ]
    [ Ensure        = [String] {'Present', 'Absent'} ]
}
```

# Common Properties

- __ProjectName__: The name of the Azure DevOps project. This is a key property.
- __EnvironmentName__: The name of the pipeline environment. This is a key property.
- __GroupName__: The name of the group to grant permissions to. This is a key property. Use the format `[ProjectName]\GroupName`.
- __isInherited__: Whether permissions are inherited. Defaults to `$true`.
- __Permissions__: An array of permission hashtables specifying the permissions to grant or deny.
- __Ensure__: Specifies whether the permissions should exist. Valid values are `Present` and `Absent`. Defaults to `Present`.

## Permissions Syntax

``` PowerShell
AzDoEnvironmentPermission/Permissions
{
    Permission = [String]$PermissionName
    Access     = [String] {'Allow', 'Deny', 'NotSet'}
}
```

## Permission List

| Name | Description |
| ---- | ----------- |
| View | View the environment |
| Manage | Manage the environment |
| Use | Use the environment in pipelines |
| Administer | Administer the environment |

# Additional Information

This resource manages security permissions on Azure DevOps pipeline environments, controlling which groups or users can view, use, or administer specific environments.

# Examples

## Example 1: Grant environment permissions

``` PowerShell
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoEnvironmentPermission 'AddEnvironmentPermission' {
            Ensure          = 'Present'
            ProjectName     = 'MyProject'
            EnvironmentName = 'Production'
            GroupName       = '[MyProject]\Contributors'
            isInherited     = $true
            Permissions     = @(
                @{ Permission = 'View'; Access = 'Allow' }
                @{ Permission = 'Use'; Access = 'Allow' }
            )
        }
    }
}
```
