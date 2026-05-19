# DSC AzDoServiceConnectionPermission Resource

# Syntax

``` PowerShell
AzDoServiceConnectionPermission [string] #ResourceName
{
    ProjectName     = [String]$ProjectName
    ConnectionName  = [String]$ConnectionName
    GroupName       = [String]$GroupName
    [ isInherited   = [Boolean]$isInherited ]
    [ Permissions   = [HashTable[]]$Permissions ]
    [ Ensure        = [String] {'Present', 'Absent'} ]
}
```

# Common Properties

- __ProjectName__: The name of the Azure DevOps project. This is a key property.
- __ConnectionName__: The name of the service connection. This is a key property.
- __GroupName__: The name of the group to grant permissions to. This is a key property. Use the format `[ProjectName]\GroupName`.
- __isInherited__: Whether permissions are inherited. Defaults to `$true`.
- __Permissions__: An array of permission hashtables specifying the permissions to grant or deny.
- __Ensure__: Specifies whether the permissions should exist. Valid values are `Present` and `Absent`. Defaults to `Present`.

## Permissions Syntax

``` PowerShell
AzDoServiceConnectionPermission/Permissions
{
    Permission = [String]$PermissionName
    Access     = [String] {'Allow', 'Deny', 'NotSet'}
}
```

## Permission List

| Name | Description |
| ---- | ----------- |
| Use | Use the service connection in pipelines |
| Administer | Administer the service connection |
| ViewAuthorization | View the service connection authorization |
| ViewEndpoint | View the service connection details |

# Additional Information

This resource manages security permissions on Azure DevOps service connections, controlling which groups or users can use or manage specific service connections in pipelines.

# Examples

## Example 1: Grant service connection permissions

``` PowerShell
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoServiceConnectionPermission 'AddServiceConnectionPermission' {
            Ensure         = 'Present'
            ProjectName    = 'MyProject'
            ConnectionName = 'MyAzureServiceConnection'
            GroupName      = '[MyProject]\Contributors'
            isInherited    = $true
            Permissions    = @(
                @{ Permission = 'Use'; Access = 'Allow' }
            )
        }
    }
}
```
