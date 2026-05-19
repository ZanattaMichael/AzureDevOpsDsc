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

## Properties

### Common Properties

- **ProjectName**: The name of the Azure DevOps project. This property is mandatory and serves as a key property for the resource.
- **GroupName**: The name of the group to grant permissions to. This is a key property. Use the format `[ProjectName]\GroupName` or `[TEAM FOUNDATION]\GroupName` for organization-level groups.
- **isInherited**: Whether permissions are inherited from parent objects. Defaults to `$true`.
- **Permissions**: An array of permission hashtables specifying the permissions to grant or deny.
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
                @{ Permission = 'GENERIC_READ'; Access = 'Allow' }
                @{ Permission = 'GENERIC_WRITE'; Access = 'Allow' }
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
        @{ Permission = 'GENERIC_READ'; Access = 'Allow' }
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
      - Permission: GENERIC_READ
        Access: Allow
      - Permission: GENERIC_WRITE
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
