# DSC AzDoPipelineEnvironment Resource

## Syntax

```PowerShell
AzDoPipelineEnvironment [string] #ResourceName
{
    ProjectName       = [String]$ProjectName
    EnvironmentName   = [String]$EnvironmentName
    [ Description     = [String]$Description ]
    [ Ensure          = [String] {'Present', 'Absent'} ]
}
```

## Properties

### Common Properties

- **ProjectName**: The name of the Azure DevOps project. This property is mandatory and serves as a key property for the resource.
- **EnvironmentName**: The name of the pipeline environment. This is a key property.
- **Description**: An optional description for the environment.
- **Ensure**: Specifies whether the environment should exist. Valid values are `Present` and `Absent`.

## Additional Information

This resource manages pipeline environments in Azure DevOps. Environments represent deployment targets (e.g., Development, Staging, Production) and can be configured with approval gates and checks using the `AzDoEnvironmentApproval` and `AzDoCheckConfiguration` resources.

## Examples

## Example 1: Sample Configuration using AzDoPipelineEnvironment Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoPipelineEnvironment AddEnvironment {
            Ensure          = 'Present'
            ProjectName     = 'MyProject'
            EnvironmentName = 'Production'
            Description     = 'Production deployment environment'
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoPipelineEnvironment
$properties = @{
    ProjectName     = 'MyProject'
    EnvironmentName = 'Production'
}

Invoke-DscResource -Name 'AzDoPipelineEnvironment' -Method Get -Property $properties -ModuleName 'AzureDevOpsDsc'
```

## Example 3: Sample Configuration using AzDO-DSC-LCM

``` YAML
parameters: {}

variables: {
  ProjectName: MyProject,
  EnvironmentName: Production
}

resources:
- name: Production Environment
  type: AzureDevOpsDsc/AzDoPipelineEnvironment
  dependsOn:
    - AzureDevOpsDsc/AzDevOpsProject/MyProject
  properties:
    ProjectName: $ProjectName
    EnvironmentName: $EnvironmentName
    Description: Production deployment environment
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
