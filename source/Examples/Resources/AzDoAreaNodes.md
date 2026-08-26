# DSC AzDoAreaNodes Resource

## Syntax

```PowerShell
AzDoAreaNodes [string] #ResourceName
{
    ProjectName  = [String]$ProjectName
    [ AreaPaths  = [String[]]$AreaPaths ]
    [ Ensure     = [String] {'Present', 'Absent'} ]
}
```

## Properties

### Common Properties

- **ProjectName**: The name of the Azure DevOps project. This property is mandatory and serves as the key property for the resource.
- **AreaPaths**: An array of area path strings to create or maintain. Paths should use backslash separators relative to the project root (e.g., `MyProject\Team Alpha\Frontend`).
- **Ensure**: Specifies whether the area nodes should exist. Valid values are `Present` and `Absent`.

## Additional Information

This resource manages the area path hierarchy within an Azure DevOps project. Area paths are used to organize work items and can be assigned to teams to define their scope of work.

## Examples

## Example 1: Sample Configuration using AzDoAreaNodes Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    Node localhost {
        AzDoAreaNodes AddAzDoAreaNodes {
            Ensure      = 'Present'
            ProjectName = 'MyProject'
            AreaPaths   = @(
                'MyProject\Team Alpha'
                'MyProject\Team Alpha\Frontend'
                'MyProject\Team Beta'
            )
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoAreaNodes
$properties = @{
    ProjectName = 'MyProject'
    AreaPaths   = @(
        'MyProject\Team Alpha'
        'MyProject\Team Alpha\Frontend'
        'MyProject\Team Beta'
    )
}

Invoke-DscResource -Name 'AzDoAreaNodes' -Method Get -Property $properties -ModuleName 'AzureDevOpsDscNative'
```

## Example 3: Sample Configuration using Dsc.PipelineRunner

``` YAML
parameters: {}

variables: {
  ProjectName: MyProject
}

resources:
- name: MyProject Area Nodes
  type: AzureDevOpsDscNative/AzDoAreaNodes
  dependsOn:
    - AzureDevOpsDscNative/AzDoProject/MyProject
  properties:
    ProjectName: $ProjectName
    AreaPaths:
      - '$ProjectName\Team Alpha'
      - '$ProjectName\Team Alpha\Frontend'
      - '$ProjectName\Team Beta'
    Ensure: Present
```

Pipeline runner initialization:

``` PowerShell

Import-Module Dsc.PipelineRunner

$params = @{
    AzureDevopsOrganizationName = "SampleAzDoOrgName"
    exportConfigDir             = "C:\Datum\DSCOutput\"
    ConfigurationSourcePath     = 'https://configuration-path'
    JITToken                    = 'SampleJITToken'
    Mode                        = 'Set'
    AuthenticationType          = 'ManagedIdentity'
    ReportPath                  = 'C:\Datum\DSCOutput\Reports'
}

Invoke-DscPipelineRunner @params
```
