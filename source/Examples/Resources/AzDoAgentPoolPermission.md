# DSC AzDoAgentPoolPermission Resource

## Syntax

```PowerShell
AzDoAgentPoolPermission [string] #ResourceName
{
    PoolName      = [String]$PoolName
    GroupName     = [String]$GroupName
    [ isInherited = [Boolean]$isInherited ]
    [ Permissions = [HashTable[]]$Permissions ]
    [ Ensure      = [String] {'Present', 'Absent'} ]
}
```

## Permissions Syntax

``` PowerShell
AzDoAgentPoolPermission/Permissions
{
    Identity   = [String]$Identity # Syntax
    #   SYNTAX:     '[ProjectName | OrganizationName]\ServicePrincipalName, UserPrincipalName, UserDisplayName, GroupDisplayName'
    #   EXAMPLE:    '[TestProject]\UserName@email.com'
    #   EXAMPLE:    '[SampleOrganizationName]\Project Collection Administrators'
    Permission = [Hashtable]$Permissions # See 'Permission List'
}
```

## Permission Usage

``` PowerShell
AzDoAgentPoolPermission/Permissions/Permission
{
    PermissionName|PermissionDisplayName = [String]$Name { 'Allow, Deny' }
}
```

## Permission List

> Either 'Name' or 'DisplayName' can be used, but we Strongly Recommend that you use 'Name' in your configuration.

| Name | DisplayName | Values | Note |
| ---- | ----------- | ------ | ---- |
| Use | Use | [ allow, deny ] | |
| Manage | Manage | [ allow, deny ] | Not recommended. |
| Create | Create | [ allow, deny ] | |
| ViewAuthorization | View Authorization | [ allow, deny ] | |
| ManagePermissions | Manage Permissions | [ allow, deny ] | Not recommended. |

## Properties

### Common Properties

- **PoolName**: The name of the agent pool. This property is mandatory and serves as the key property for the resource.
- **GroupName**: The name of the group to grant permissions to. This is a key property. Use the format `[ProjectName]\GroupName` or `[TEAM FOUNDATION]\GroupName` for organization-level groups.
- **isInherited**: Whether permissions are inherited. Defaults to `$true`.
- **Permissions**: A HashTable that specifies the permissions to be set. Refer to: 'Permissions Syntax'.
- **Ensure**: Specifies whether the permissions should exist. Valid values are `Present` and `Absent`.

## Additional Information

This resource manages security permissions on Azure DevOps agent pools, controlling which groups or users can use or administer the pool.

## Examples

## Example 1: Sample Configuration using AzDoAgentPoolPermission Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoAgentPoolPermission AddAgentPoolPermission {
            Ensure      = 'Present'
            PoolName    = 'MyPool'
            GroupName   = '[MyProject]\Contributors'
            isInherited = $true
            Permissions = @(
                @{
                    Identity   = '[MyProject]\Contributors'
                    Permission = @{
                        'Use' = 'Allow'
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
# Return the current configuration for AzDoAgentPoolPermission
$properties = @{
    PoolName    = 'MyPool'
    GroupName   = '[MyProject]\Contributors'
    isInherited = $true
    Permissions = @(
        @{
            Identity   = '[MyProject]\Contributors'
            Permission = @{
                'Use' = 'Allow'
            }
        }
    )
}

Invoke-DscResource -Name 'AzDoAgentPoolPermission' -Method Get -Property $properties -ModuleName 'AzureDevOpsDsc'
```

## Example 3: Sample Configuration using AzDO-DSC-LCM

``` YAML
parameters: {}

variables: {
  ProjectName: MyProject,
  PoolName: MyPool
}

resources:
- name: Agent Pool Contributors Permission
  type: AzureDevOpsDsc/AzDoAgentPoolPermission
  dependsOn:
    - AzureDevOpsDsc/AzDoAgentPool/MyPool
  properties:
    PoolName: $PoolName
    GroupName: '[$ProjectName]\Contributors'
    isInherited: true
    Permissions:
      - Identity: '[$ProjectName]\Contributors'
        Permission:
          Use: Allow
    Ensure: Present
```

LCM Initialization:

``` PowerShell

$params = @{
    AzureDevopsOrganizationName = "SampleAzDoOrgName"
    ConfigurationDirectory      = "C:\Datum\DSCOutput\"
    ConfigurationUrl            = 'https://configuration-path'
    JITToken                    = 'SampleJITToken'
    Mode                        = 'Set'
    AuthenticationType          = 'ManagedIdentity'
    ReportPath                  = 'C:\Datum\DSCOutput\Reports'
}

Invoke-AzDoLCM @params
```
