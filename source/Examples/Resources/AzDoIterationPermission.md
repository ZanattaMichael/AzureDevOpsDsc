# DSC AzDoIterationPermission Resource

# Syntax

``` PowerShell
AzDoIterationPermission [string] #ResourceName
{
    ProjectName    = [String]$ProjectName
    IterationPath  = [String]$IterationPath
    [ isInherited  = [Boolean]$isInherited ]
    [ Permissions  = [HashTable[]]$Permissions ]
    [ Ensure       = [String] {'Present', 'Absent'} ]
}
```

The `IterationPath` property is optional. If it is not provided, the permissions will be applied at the project-level iterations node.

## Permissions Syntax

``` PowerShell
AzDoIterationPermission/Permissions
{
    Identity   = [String]$Identity
    #   SYNTAX:     '[ProjectName | OrganizationName]\ServicePrincipalName, UserPrincipalName, UserDisplayName, GroupDisplayName'
    #   EXAMPLE:    '[TestProject]\TeamName'
    Permission = [Hashtable]$Permissions
}
```

## Permission List

| Name | DisplayName | Values |
| ---- | ----------- | ------ |
| GENERIC_READ | View this node | [ allow, deny ] |
| GENERIC_WRITE | Edit this node | [ allow, deny ] |
| CREATE_CHILDREN | Create child nodes | [ allow, deny ] |
| DELETE | Delete this node | [ allow, deny ] |
| WORK_ITEM_READ | View work items in this node | [ allow, deny ] |
| WORK_ITEM_WRITE | Edit work items in this node | [ allow, deny ] |
| MANAGE_TEST_PLANS | Manage test plans | [ allow, deny ] |
| MANAGE_TEST_SUITES | Manage test suites | [ allow, deny ] |

# Common Properties

- __ProjectName__: The name of the Azure DevOps project.
- __IterationPath__: The iteration path to set permissions on (e.g., `\Sprint 1\Sub Sprint`). If omitted, permissions apply at the root iteration level.
- __isInherited__: Whether permissions are inherited. Defaults to `$true`.
- __Permissions__: An array of permission hashtables specifying the permissions to set.
- __Ensure__: Specifies whether the permissions should exist. Defaults to `Present`.

# Additional Information

This resource allows you to manage Azure DevOps iteration path permissions using Desired State Configuration (DSC). It controls which users or groups can view, edit, or manage work items within specific iteration paths.

# Examples

## Example 1: Grant iteration permissions to a team

``` PowerShell
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoIterationPermission 'AddIterationPermission' {
            Ensure        = 'Present'
            ProjectName   = 'MyProject'
            IterationPath = '\MyProject\Sprint 1'
            isInherited   = $false
            Permissions   = @(
                @{
                    Identity   = '[MyProject]\My Team'
                    Permission = @{
                        'WORK_ITEM_READ'  = 'Allow'
                        'WORK_ITEM_WRITE' = 'Allow'
                    }
                }
            )
        }
    }
}
```

## Example 2: Using Invoke-DscResource

``` PowerShell
$properties = @{
    ProjectName   = 'MyProject'
    IterationPath = '\MyProject\Sprint 1'
    isInherited   = $false
    Permissions   = @(
        @{
            Identity   = '[MyProject]\My Team'
            Permission = @{
                'WORK_ITEM_READ'  = 'Allow'
                'WORK_ITEM_WRITE' = 'Allow'
            }
        }
    )
}

Invoke-DscResource -Name 'AzDoIterationPermission' -Method Get -Property $properties -ModuleName 'AzureDevOpsDsc'
```
