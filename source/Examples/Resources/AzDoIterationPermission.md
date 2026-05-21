# DSC AzDoIterationPermission Resource

## Syntax

```PowerShell
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

## Properties

### Common Properties

- **ProjectName**: The name of the Azure DevOps project. This property is mandatory and serves as a key property for the resource.
- **IterationPath**: The iteration path to set permissions on (e.g., `\MyProject\Sprint 1`). If omitted, permissions apply at the root iteration level.
- **isInherited**: Whether permissions are inherited. Defaults to `$true`.
- **Permissions**: An array of permission hashtables specifying the permissions to set.
- **Ensure**: Specifies whether the permissions should exist. Valid values are `Present` and `Absent`.

### Permissions Syntax

``` PowerShell
AzDoIterationPermission/Permissions
{
    Identity   = [String]$Identity
    #   SYNTAX:     '[ProjectName | OrganizationName]\GroupDisplayName'
    #   EXAMPLE:    '[MyProject]\My Team'
    Permission = [Hashtable]$Permissions
}
```

### Permission List

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

## Additional Information

This resource allows you to manage Azure DevOps iteration path permissions using Desired State Configuration (DSC). It controls which users or groups can view, edit, or manage work items within specific iteration paths.

## Examples

## Example 1: Sample Configuration using AzDoIterationPermission Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoIterationPermission AddIterationPermission {
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

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoIterationPermission
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

## Example 3: Sample Configuration using AzDO-DSC-LCM

``` YAML
parameters: {}

variables: {
  ProjectName: MyProject
}

resources:
- name: Sprint 1 Team Permissions
  type: AzureDevOpsDsc/AzDoIterationPermission
  dependsOn:
    - AzureDevOpsDsc/AzDoIterationNodes/MyProject
  properties:
    ProjectName: $ProjectName
    IterationPath: '\$ProjectName\Sprint 1'
    isInherited: false
    Permissions:
      - Identity: '[$ProjectName]\My Team'
        Permission:
          WORK_ITEM_READ: Allow
          WORK_ITEM_WRITE: Allow
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
