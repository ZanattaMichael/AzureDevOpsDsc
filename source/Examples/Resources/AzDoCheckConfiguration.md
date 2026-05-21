# DSC AzDoCheckConfiguration Resource

## Syntax

```PowerShell
AzDoCheckConfiguration [string] #ResourceName
{
    ProjectName          = [String]$ProjectName
    ResourceName         = [String]$ResourceName
    ResourceType         = [String] {'environment', 'repository', 'endpoint'}
    CheckType            = [String]$CheckType
    [ Settings           = [HashTable]$Settings ]
    [ TimeoutInMinutes   = [UInt32]$TimeoutInMinutes ]
    [ Enabled            = [Boolean]$Enabled ]
    [ Ensure             = [String] {'Present', 'Absent'} ]
}
```

## Properties

### Common Properties

- **ProjectName**: The name of the Azure DevOps project. This property is mandatory and serves as a key property for the resource.
- **ResourceName**: The name of the resource to attach the check to (environment name, repository name, or service connection name). This is a key property.
- **ResourceType**: The type of resource. Valid values are `environment`, `repository`, and `endpoint`. This is a key property.
- **CheckType**: The type of check to configure (e.g., `Task Check`, `Approval`, `ExclusiveLock`). This is a key property.
- **Settings**: A hashtable of check-specific configuration settings.
- **TimeoutInMinutes**: How long the check can run before timing out. Defaults to `43200` (30 days).
- **Enabled**: Whether the check is active. Defaults to `$true`.
- **Ensure**: Specifies whether the check should exist. Valid values are `Present` and `Absent`.

## Additional Information

This resource manages pipeline check configurations on Azure DevOps resources such as environments, repositories, and service connections. Checks enforce gates that must pass before a pipeline can access the protected resource.

## Examples

## Example 1: Sample Configuration using AzDoCheckConfiguration Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoCheckConfiguration AddExclusiveLock {
            Ensure           = 'Present'
            ProjectName      = 'MyProject'
            ResourceName     = 'Production'
            ResourceType     = 'environment'
            CheckType        = 'ExclusiveLock'
            TimeoutInMinutes = 43200
            Enabled          = $true
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoCheckConfiguration
$properties = @{
    ProjectName  = 'MyProject'
    ResourceName = 'Production'
    ResourceType = 'environment'
    CheckType    = 'ExclusiveLock'
}

Invoke-DscResource -Name 'AzDoCheckConfiguration' -Method Get -Property $properties -ModuleName 'AzureDevOpsDsc'
```

## Example 3: Sample Configuration using AzDO-DSC-LCM

``` YAML
parameters: {}

variables: {
  ProjectName: MyProject,
  EnvironmentName: Production
}

resources:
- name: Production Exclusive Lock
  type: AzureDevOpsDsc/AzDoCheckConfiguration
  dependsOn:
    - AzureDevOpsDsc/AzDoPipelineEnvironment/Production
  properties:
    ProjectName: $ProjectName
    ResourceName: $EnvironmentName
    ResourceType: environment
    CheckType: ExclusiveLock
    TimeoutInMinutes: 43200
    Enabled: true
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
