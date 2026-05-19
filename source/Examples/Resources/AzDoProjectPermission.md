# DSC AzDoProjectPermission Resource

# Syntax

``` PowerShell
AzDoProjectPermission [string] #ResourceName
{
    ProjectName   = [String]$ProjectName
    GroupName     = [String]$GroupName
    [ isInherited = [Boolean]$isInherited ]
    [ Permissions = [HashTable[]]$Permissions ]
    [ Ensure      = [String] {'Present', 'Absent'} ]
}
```

# Common Properties

- __ProjectName__: The name of the Azure DevOps project. This is a key property.
- __GroupName__: The name of the group to grant permissions to. This is a key property. Use the format `[ProjectName]\GroupName` or `[TEAM FOUNDATION]\GroupName` for organization-level groups.
- __isInherited__: Whether permissions are inherited from parent objects. Defaults to `$true`.
- __Permissions__: An array of permission hashtables specifying the permissions to grant or deny.
- __Ensure__: Specifies whether the permissions should exist. Valid values are `Present` and `Absent`. Defaults to `Present`.

## Permissions Syntax

``` PowerShell
AzDoProjectPermission/Permissions
{
    Permission = [String]$PermissionName
    Access     = [String] {'Allow', 'Deny', 'NotSet'}
}
```

## Permission List

| Name | Description |
| ---- | ----------- |
| GENERIC_READ | View project-level information |
| GENERIC_WRITE | Edit project-level information |
| DELETE | Delete the project |
| PUBLISH_TEST_RESULTS | Publish test results |
| ADMINISTER_BUILD | Administer builds |
| START_BUILD | Start builds |
| EDIT_BUILD_STATUS | Edit build status |
| UPDATE_BUILD | Update builds |
| DELETE_TEST_RESULTS | Delete test results |
| VIEW_TEST_RUNS | View test runs |
| MANAGE_TEST_ENVIRONMENTS | Manage test environments |
| MANAGE_TEST_CONFIGURATIONS | Manage test configurations |
| WORK_ITEM_DELETE | Delete and restore work items |
| WORK_ITEM_MOVE | Move work items |
| WORK_ITEM_PERMANENTLY_DELETE | Permanently delete work items |
| RENAME | Rename project |
| MANAGE_PROPERTIES | Manage project properties |
| MANAGE_SYSTEM_PROPERTIES | Manage system project properties |
| BYPASS_RULES | Bypass rules on work item updates |
| SUPPRESS_NOTIFICATIONS | Suppress notifications |

# Additional Information

This resource manages project-level permissions in Azure DevOps, controlling what actions groups or users can perform within a specific project.

# Examples

## Example 1: Grant project permissions to a group

``` PowerShell
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoProjectPermission 'AddProjectPermission' {
            Ensure      = 'Present'
            ProjectName = 'MyProject'
            GroupName   = '[MyProject]\Contributors'
            isInherited = $true
            Permissions = @(
                @{ Permission = 'GENERIC_READ'; Access = 'Allow' }
                @{ Permission = 'GENERIC_WRITE'; Access = 'Allow' }
            )
        }
    }
}
```
