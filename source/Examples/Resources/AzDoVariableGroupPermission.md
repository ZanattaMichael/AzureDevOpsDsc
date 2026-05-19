# DSC AzDoVariableGroupPermission Resource

# Syntax

``` PowerShell
AzDoVariableGroupPermission [string] #ResourceName
{
    ProjectName         = [String]$ProjectName
    VariableGroupName   = [String]$VariableGroupName
    GroupName           = [String]$GroupName
    [ isInherited       = [Boolean]$isInherited ]
    [ Permissions       = [HashTable[]]$Permissions ]
    [ Ensure            = [String] {'Present', 'Absent'} ]
}
```

# Common Properties

- __ProjectName__: The name of the Azure DevOps project. This is a key property.
- __VariableGroupName__: The name of the variable group. This is a key property.
- __GroupName__: The name of the group to grant permissions to. This is a key property. Use the format `[ProjectName]\GroupName`.
- __isInherited__: Whether permissions are inherited. Defaults to `$true`.
- __Permissions__: An array of permission hashtables specifying the permissions to grant or deny.
- __Ensure__: Specifies whether the permissions should exist. Valid values are `Present` and `Absent`. Defaults to `Present`.

## Permissions Syntax

``` PowerShell
AzDoVariableGroupPermission/Permissions
{
    Permission = [String]$PermissionName
    Access     = [String] {'Allow', 'Deny', 'NotSet'}
}
```

## Permission List

| Name | Description |
| ---- | ----------- |
| Use | Use the variable group in pipelines |
| Administer | Manage the variable group |
| View | View the variable group |
| Edit | Edit the variable group |

# Additional Information

This resource manages security permissions on Azure DevOps variable groups, controlling which groups or users can use or administer specific variable groups.

# Examples

## Example 1: Grant variable group permissions

``` PowerShell
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoVariableGroupPermission 'AddVariableGroupPermission' {
            Ensure            = 'Present'
            ProjectName       = 'MyProject'
            VariableGroupName = 'MyVariableGroup'
            GroupName         = '[MyProject]\Contributors'
            isInherited       = $true
            Permissions       = @(
                @{ Permission = 'Use'; Access = 'Allow' }
            )
        }
    }
}
```
