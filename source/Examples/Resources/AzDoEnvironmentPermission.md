# DSC AzDoEnvironmentPermission Resource

## Syntax

```PowerShell
AzDoEnvironmentPermission [string] #ResourceName
{
    ProjectName     = [String]$ProjectName
    EnvironmentName = [String]$EnvironmentName
    GroupName       = [String]$GroupName
    [ isInherited   = [Boolean]$isInherited ]
    [ Permissions   = [HashTable[]]$Permissions ]
    [ Ensure        = [String] {'Present', 'Absent'} ]
}
```

## Properties

### Common Properties

- **ProjectName**: The name of the Azure DevOps project. This property is mandatory and serves as a key property for the resource.
- **EnvironmentName**: The name of the pipeline environment. This is a key property.
- **GroupName**: The name of the group to grant permissions to. This is a key property. Use the format `[ProjectName]\GroupName`.
- **isInherited**: Whether permissions are inherited. Defaults to `$true`.
- **Permissions**: An array of permission hashtables specifying the permissions to grant or deny.
- **Ensure**: Specifies whether the permissions should exist. Valid values are `Present` and `Absent`.

## Additional Information

This resource manages security permissions on Azure DevOps pipeline environments, controlling which groups or users can view, use, or administer specific environments.

## Examples

## Example 1: Sample Configuration using AzDoEnvironmentPermission Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoEnvironmentPermission AddEnvironmentPermission {
            Ensure          = 'Present'
            ProjectName     = 'MyProject'
            EnvironmentName = 'Production'
            GroupName       = '[MyProject]\Contributors'
            isInherited     = $true
            Permissions     = @(
                @{ Permission = 'View'; Access = 'Allow' }
                @{ Permission = 'Use'; Access = 'Allow' }
            )
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoEnvironmentPermission
$properties = @{
    ProjectName     = 'MyProject'
    EnvironmentName = 'Production'
    GroupName       = '[MyProject]\Contributors'
    isInherited     = $true
    Permissions     = @(
        @{ Permission = 'View'; Access = 'Allow' }
    )
}

Invoke-DscResource -Name 'AzDoEnvironmentPermission' -Method Get -Property $properties -ModuleName 'AzureDevOpsDsc'
```

## Example 3: Sample Configuration using AzDO-DSC-LCM

``` YAML
parameters: {}

variables: {
  ProjectName: MyProject,
  EnvironmentName: Production
}

resources:
- name: Production Environment Contributors Permission
  type: AzureDevOpsDsc/AzDoEnvironmentPermission
  dependsOn:
    - AzureDevOpsDsc/AzDoPipelineEnvironment/Production
  properties:
    ProjectName: $ProjectName
    EnvironmentName: $EnvironmentName
    GroupName: '[$ProjectName]\Contributors'
    isInherited: true
    Permissions:
      - Permission: View
        Access: Allow
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
