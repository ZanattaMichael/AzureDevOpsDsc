# DSC AzDoAnalyticsPermission Resource

## Syntax

```PowerShell
AzDoAnalyticsPermission [string] #ResourceName
{
    ProjectName   = [String]$ProjectName
    GroupName     = [String]$GroupName
    [ isInherited = [Boolean]$isInherited ]
    [ Permissions = [HashTable[]]$Permissions ]
    [ Ensure      = [String] {'Present', 'Absent'} ]
}
```

## Permissions Syntax

``` PowerShell
AzDoAnalyticsPermission/Permissions
{
    Identity   = [String]$Identity # Syntax
    #   SYNTAX:     '[ProjectName | OrganizationName]\ServicePrincipalName, UserPrincipalName, UserDisplayName, GroupDisplayName'
    #   EXAMPLE:    '[TestProject]\Contributors'
    Permission = [Hashtable]$Permissions # See 'Permission List'
}
```

## Permission Usage

``` PowerShell
AzDoAnalyticsPermission/Permissions/Permission
{
    PermissionName|PermissionDisplayName = [String]$Name { 'Allow, Deny' }
}
```

## Permission List

> Either 'Name' or 'DisplayName' can be used. The resource never hardcodes permission bits - it
> resolves the action by name (or display name) against the live `Analytics` security namespace
> (`_apis/securitynamespaces`) at apply time, so this table is a reference, not the source of truth.

| Name | DisplayName | Note |
| ---- | ----------- | ---- |
| Read | View analytics | View analytics data for the project. |
| Administer | Manage analytics permissions | Manage the Analytics namespace's own ACLs. |
| Stage | Push the data to staging area | Used internally by the analytics data pipeline. |
| ExecuteUnrestrictedQuery | Execute query without any restrictions on the query form | Bypass query-shape restrictions. |
| ReadEuii | Read EUII data | Read end-user-identifiable-information fields. |

## Properties

### Common Properties

- **ProjectName**: The name of the Azure DevOps project. This property is mandatory and serves as the key property for the resource.
- **GroupName**: The name of the group to grant analytics permissions to. Use the format `[ProjectName]\GroupName`.
- **isInherited**: Whether permissions are inherited from parent objects. Defaults to `$true`.
- **Permissions**: A HashTable that specifies the permissions to be set. Refer to: 'Permissions Syntax'.
- **Ensure**: Specifies whether the permissions should exist. Valid values are `Present` and `Absent`.

## Additional Information

This resource manages permissions on the project-scoped `Analytics` security namespace, which
governs who can view analytics data (token shape `$/{projectId}`).

## Examples

## Example 1: Sample Configuration using AzDoAnalyticsPermission Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    Node localhost {
        AzDoAnalyticsPermission AddAnalyticsPermission {
            Ensure      = 'Present'
            ProjectName = 'MyProject'
            GroupName   = '[MyProject]\Contributors'
            isInherited = $false
            Permissions = @(
                @{
                    Identity   = '[MyProject]\Contributors'
                    Permission = @{
                        'Read' = 'Deny'
                    }
                }
            )
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
$properties = @{
    ProjectName = 'MyProject'
    GroupName   = '[MyProject]\Contributors'
    isInherited = $false
    Permissions = @(
        @{
            Identity   = '[MyProject]\Contributors'
            Permission = @{
                'Read' = 'Deny'
            }
        }
    )
}

Invoke-DscResource -Name 'AzDoAnalyticsPermission' -Method Get -Property $properties -ModuleName 'AzureDevOpsDscNative'
```
