# DSC AzDoVariableGroupPermission Resource

## Syntax

```PowerShell
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

## Permissions Syntax

``` PowerShell
AzDoVariableGroupPermission/Permissions
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
AzDoVariableGroupPermission/Permissions/Permission
{
    PermissionName|PermissionDisplayName = [String]$Name { 'Allow, Deny' }
}
```

## Permission List

> Either 'Name' or 'DisplayName' can be used, but we Strongly Recommend that you use 'Name' in your configuration.

| Name | DisplayName | Values | Note |
| ---- | ----------- | ------ | ---- |
| View | View library item | [ allow, deny ] | |
| Administer | Administer library item | [ allow, deny ] | Not recommended. |
| Create | Create library item | [ allow, deny ] | |
| ViewSecrets | View library item secrets | [ allow, deny ] | |
| Use | Use library item | [ allow, deny ] | |
| Owner | Owner library item | [ allow, deny ] | Not recommended. |

## Properties

### Common Properties

- **ProjectName**: The name of the Azure DevOps project. This property is mandatory and serves as a key property for the resource.
- **VariableGroupName**: The name of the variable group. This is a key property.
- **GroupName**: The name of the group to grant permissions to. This is a key property. Use the format `[ProjectName]\GroupName`.
- **isInherited**: Whether permissions are inherited. Defaults to `$true`.
- **Permissions**: A HashTable that specifies the permissions to be set. Refer to: 'Permissions Syntax'.
- **Ensure**: Specifies whether the permissions should exist. Valid values are `Present` and `Absent`.

## Additional Information

This resource manages security permissions on Azure DevOps variable groups (Library security namespace), controlling which groups or users can use, view secrets, or administer specific variable groups in pipelines.

## Examples

## Example 1: Sample Configuration using AzDoVariableGroupPermission Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoVariableGroupPermission AddVariableGroupPermission {
            Ensure            = 'Present'
            ProjectName       = 'MyProject'
            VariableGroupName = 'MyVariableGroup'
            GroupName         = '[MyProject]\Contributors'
            isInherited       = $true
            Permissions       = @(
                @{
                    Identity   = '[MyProject]\Contributors'
                    Permission = @{
                        'View' = 'Allow'
                        'Use'  = 'Allow'
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
# Return the current configuration for AzDoVariableGroupPermission
$properties = @{
    ProjectName       = 'MyProject'
    VariableGroupName = 'MyVariableGroup'
    GroupName         = '[MyProject]\Contributors'
    isInherited       = $true
    Permissions       = @(
        @{
            Identity   = '[MyProject]\Contributors'
            Permission = @{
                'View' = 'Allow'
                'Use'  = 'Allow'
            }
        }
    )
}

Invoke-DscResource -Name 'AzDoVariableGroupPermission' -Method Get -Property $properties -ModuleName 'AzureDevOpsDsc'
```

## Example 3: Sample Configuration using AzDO-DSC-LCM

``` YAML
parameters: {}

variables: {
  ProjectName: MyProject,
  VariableGroupName: MyVariableGroup
}

resources:
- name: Variable Group Contributors Permission
  type: AzureDevOpsDsc/AzDoVariableGroupPermission
  dependsOn:
    - AzureDevOpsDsc/AzDoVariableGroup/MyVariableGroup
  properties:
    ProjectName: $ProjectName
    VariableGroupName: $VariableGroupName
    GroupName: '[$ProjectName]\Contributors'
    isInherited: true
    Permissions:
      - Identity: '[$ProjectName]\Contributors'
        Permission:
          View: Allow
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
