# DSC AzDoProjectPermission Resource

## Syntax

```PowerShell
AzDoProjectPermission [string] #ResourceName
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
AzDoProjectPermission/Permissions
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
AzDoProjectPermission/Permissions/Permission
{
    PermissionName|PermissionDisplayName = [String]$Name { 'Allow, Deny' }
}
```

## Permission List

> Either 'Name' or 'DisplayName' can be used, but we Strongly Recommend that you use 'Name' in your configuration.

| Name | DisplayName | Values | Note |
| ---- | ----------- | ------ | ---- |
| GENERIC_READ | View project-level information | [ allow, deny ] | |
| GENERIC_WRITE | Edit project-level information | [ allow, deny ] | |
| DELETE | Delete team project | [ allow, deny ] | Not recommended. |
| PUBLISH_TEST_RESULTS | Publish test results | [ allow, deny ] | |
| ADMINISTER_BUILD | Administer a build | [ allow, deny ] | |
| START_BUILD | Start a build | [ allow, deny ] | |
| EDIT_BUILD_STATUS | Edit build quality | [ allow, deny ] | |
| UPDATE_BUILD | Write to build operational store | [ allow, deny ] | |
| DELETE_TEST_RESULTS | Delete test runs | [ allow, deny ] | |
| VIEW_TEST_RUNS | View test runs | [ allow, deny ] | |
| MANAGE_TEST_ENVIRONMENTS | Manage test environments | [ allow, deny ] | |
| MANAGE_TEST_CONFIGURATIONS | Manage test configurations | [ allow, deny ] | |
| WORK_ITEM_DELETE | Delete and restore work items | [ allow, deny ] | |
| WORK_ITEM_MOVE | Move work items out of this project | [ allow, deny ] | |
| WORK_ITEM_PERMANENTLY_DELETE | Permanently delete work items | [ allow, deny ] | |
| RENAME | Rename team project | [ allow, deny ] | |
| MANAGE_PROPERTIES | Manage project properties | [ allow, deny ] | |
| MANAGE_SYSTEM_PROPERTIES | Manage system project properties | [ allow, deny ] | |
| BYPASS_RULES | Bypass rules on work item updates | [ allow, deny ] | |
| SUPPRESS_NOTIFICATIONS | Suppress notifications for work item updates | [ allow, deny ] | |

## Properties

### Common Properties

- **ProjectName**: The name of the Azure DevOps project. This property is mandatory and serves as a key property for the resource.
- **GroupName**: The name of the group to grant permissions to. This is a key property. Use the format `[ProjectName]\GroupName` or `[TEAM FOUNDATION]\GroupName` for organization-level groups.
- **isInherited**: Whether permissions are inherited from parent objects. Defaults to `$true`.
- **Permissions**: A HashTable that specifies the permissions to be set. Refer to: 'Permissions Syntax'.
- **Ensure**: Specifies whether the permissions should exist. Valid values are `Present` and `Absent`.

## Additional Information

This resource manages project-level permissions in Azure DevOps, controlling what actions groups or users can perform within a specific project.

## Examples

## Example 1: Sample Configuration using AzDoProjectPermission Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoProjectPermission AddProjectPermission {
            Ensure      = 'Present'
            ProjectName = 'MyProject'
            GroupName   = '[MyProject]\Contributors'
            isInherited = $true
            Permissions = @(
                @{
                    Identity   = '[MyProject]\Contributors'
                    Permission = @{
                        'GENERIC_READ'  = 'Allow'
                        'GENERIC_WRITE' = 'Allow'
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
# Return the current configuration for AzDoProjectPermission
$properties = @{
    ProjectName = 'MyProject'
    GroupName   = '[MyProject]\Contributors'
    isInherited = $true
    Permissions = @(
        @{
            Identity   = '[MyProject]\Contributors'
            Permission = @{
                'GENERIC_READ' = 'Allow'
            }
        }
    )
}

Invoke-DscResource -Name 'AzDoProjectPermission' -Method Get -Property $properties -ModuleName 'AzureDevOpsDsc'
```

## Example 3: Sample Configuration using AzDO-DSC-LCM

``` YAML
parameters: {}

variables: {
  ProjectName: MyProject
}

resources:
- name: Project Contributors Permissions
  type: AzureDevOpsDsc/AzDoProjectPermission
  dependsOn:
    - AzureDevOpsDsc/AzDoProjectGroup/Contributors
  properties:
    ProjectName: $ProjectName
    GroupName: '[$ProjectName]\Contributors'
    isInherited: true
    Permissions:
      - Identity: '[$ProjectName]\Contributors'
        Permission:
          GENERIC_READ: Allow
          GENERIC_WRITE: Allow
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
