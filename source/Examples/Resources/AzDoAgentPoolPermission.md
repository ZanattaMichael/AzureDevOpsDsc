# DSC AzDoAgentPoolPermission Resource

# Syntax

``` PowerShell
AzDoAgentPoolPermission [string] #ResourceName
{
    PoolName      = [String]$PoolName
    GroupName     = [String]$GroupName
    [ isInherited = [Boolean]$isInherited ]
    [ Permissions = [HashTable[]]$Permissions ]
    [ Ensure      = [String] {'Present', 'Absent'} ]
}
```

# Common Properties

- __PoolName__: The name of the agent pool. This is a key property.
- __GroupName__: The name of the group to grant permissions to. This is a key property. Use the format `[ProjectName]\GroupName` or `[TEAM FOUNDATION]\GroupName` for organization-level groups.
- __isInherited__: Whether permissions are inherited. Defaults to `$true`.
- __Permissions__: An array of permission hashtables specifying the permissions to grant or deny.
- __Ensure__: Specifies whether the permissions should exist. Valid values are `Present` and `Absent`. Defaults to `Present`.

## Permissions Syntax

``` PowerShell
AzDoAgentPoolPermission/Permissions
{
    Permission = [String]$PermissionName
    Access     = [String] {'Allow', 'Deny', 'NotSet'}
}
```

## Permission List

| Name | Description |
| ---- | ----------- |
| Use | Use the agent pool |
| Administer | Administer the agent pool |
| Create | Create agent pools |
| ManagePermissions | Manage permissions for the agent pool |
| ViewAuthorization | View the agent pool's authorization |

# Additional Information

This resource manages security permissions on Azure DevOps agent pools, controlling which groups or users can use or administer the pool.

# Examples

## Example 1: Grant permissions on an agent pool

``` PowerShell
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoAgentPoolPermission 'AddAgentPoolPermission' {
            Ensure      = 'Present'
            PoolName    = 'MyPool'
            GroupName   = '[MyProject]\Contributors'
            isInherited = $true
            Permissions = @(
                @{ Permission = 'Use'; Access = 'Allow' }
            )
        }
    }
}
```
