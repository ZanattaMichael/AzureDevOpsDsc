# DSC AzDoServiceConnectionPermission Resource

## Syntax

```PowerShell
AzDoServiceConnectionPermission [string] #ResourceName
{
    ProjectName     = [String]$ProjectName
    ConnectionName  = [String]$ConnectionName
    GroupName       = [String]$GroupName
    [ isInherited   = [Boolean]$isInherited ]
    [ Permissions   = [HashTable[]]$Permissions ]
    [ Ensure        = [String] {'Present', 'Absent'} ]
}
```

## Properties

### Common Properties

- **ProjectName**: The name of the Azure DevOps project. This property is mandatory and serves as a key property for the resource.
- **ConnectionName**: The name of the service connection. This is a key property.
- **GroupName**: The name of the group to grant permissions to. This is a key property. Use the format `[ProjectName]\GroupName`.
- **isInherited**: Whether permissions are inherited. Defaults to `$true`.
- **Permissions**: An array of permission hashtables specifying the permissions to grant or deny.
- **Ensure**: Specifies whether the permissions should exist. Valid values are `Present` and `Absent`.

## Additional Information

This resource manages security permissions on Azure DevOps service connections, controlling which groups or users can use or manage specific service connections in pipelines.

## Examples

## Example 1: Sample Configuration using AzDoServiceConnectionPermission Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoServiceConnectionPermission AddServiceConnectionPermission {
            Ensure         = 'Present'
            ProjectName    = 'MyProject'
            ConnectionName = 'MyAzureServiceConnection'
            GroupName      = '[MyProject]\Contributors'
            isInherited    = $true
            Permissions    = @(
                @{ Permission = 'Use'; Access = 'Allow' }
            )
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoServiceConnectionPermission
$properties = @{
    ProjectName    = 'MyProject'
    ConnectionName = 'MyAzureServiceConnection'
    GroupName      = '[MyProject]\Contributors'
    isInherited    = $true
    Permissions    = @(
        @{ Permission = 'Use'; Access = 'Allow' }
    )
}

Invoke-DscResource -Name 'AzDoServiceConnectionPermission' -Method Get -Property $properties -ModuleName 'AzureDevOpsDsc'
```

## Example 3: Sample Configuration using AzDO-DSC-LCM

``` YAML
parameters: {}

variables: {
  ProjectName: MyProject,
  ConnectionName: MyAzureServiceConnection
}

resources:
- name: Service Connection Contributors Permission
  type: AzureDevOpsDsc/AzDoServiceConnectionPermission
  dependsOn:
    - AzureDevOpsDsc/AzDoServiceConnection/MyAzureServiceConnection
  properties:
    ProjectName: $ProjectName
    ConnectionName: $ConnectionName
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
