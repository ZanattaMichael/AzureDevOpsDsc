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

## Properties

### Common Properties

- **ProjectName**: The name of the Azure DevOps project. This property is mandatory and serves as a key property for the resource.
- **VariableGroupName**: The name of the variable group. This is a key property.
- **GroupName**: The name of the group to grant permissions to. This is a key property. Use the format `[ProjectName]\GroupName`.
- **isInherited**: Whether permissions are inherited. Defaults to `$true`.
- **Permissions**: An array of permission hashtables specifying the permissions to grant or deny.
- **Ensure**: Specifies whether the permissions should exist. Valid values are `Present` and `Absent`.

## Additional Information

This resource manages security permissions on Azure DevOps variable groups, controlling which groups or users can use or administer specific variable groups.

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
                @{ Permission = 'Use'; Access = 'Allow' }
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
        @{ Permission = 'Use'; Access = 'Allow' }
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
      - Permission: Use
        Access: Allow
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
