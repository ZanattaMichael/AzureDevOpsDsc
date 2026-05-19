# DSC AzDoTaskGroup Resource

## Syntax

```PowerShell
AzDoTaskGroup [string] #ResourceName
{
    ProjectName     = [String]$ProjectName
    TaskGroupName   = [String]$TaskGroupName
    [ Description   = [String]$Description ]
    [ Category      = [String]$Category ]
    [ Tasks         = [HashTable[]]$Tasks ]
    [ Inputs        = [HashTable[]]$Inputs ]
    [ Ensure        = [String] {'Present', 'Absent'} ]
}
```

## Properties

### Common Properties

- **ProjectName**: The name of the Azure DevOps project. This property is mandatory and serves as a key property for the resource.
- **TaskGroupName**: The name of the task group. This is a key property.
- **Description**: An optional description for the task group.
- **Category**: The category of the task group (e.g., `Build`, `Deploy`, `Test`).
- **Tasks**: An array of task definition hashtables that form the task group.
- **Inputs**: An array of input parameter definitions for the task group.
- **Ensure**: Specifies whether the task group should exist. Valid values are `Present` and `Absent`.

## Additional Information

This resource manages task groups in Azure DevOps, which are reusable collections of pipeline tasks that can be shared across multiple pipelines. Task groups help enforce consistent build and deployment processes.

## Examples

## Example 1: Sample Configuration using AzDoTaskGroup Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoTaskGroup AddTaskGroup {
            Ensure        = 'Present'
            ProjectName   = 'MyProject'
            TaskGroupName = 'MyBuildTaskGroup'
            Description   = 'Reusable build steps for .NET projects'
            Category      = 'Build'
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoTaskGroup
$properties = @{
    ProjectName   = 'MyProject'
    TaskGroupName = 'MyBuildTaskGroup'
}

Invoke-DscResource -Name 'AzDoTaskGroup' -Method Get -Property $properties -ModuleName 'AzureDevOpsDsc'
```

## Example 3: Sample Configuration using AzDO-DSC-LCM

``` YAML
parameters: {}

variables: {
  ProjectName: MyProject,
  TaskGroupName: MyBuildTaskGroup
}

resources:
- name: My Build Task Group
  type: AzureDevOpsDsc/AzDoTaskGroup
  dependsOn:
    - AzureDevOpsDsc/AzDevOpsProject/MyProject
  properties:
    ProjectName: $ProjectName
    TaskGroupName: $TaskGroupName
    Description: Reusable build steps for .NET projects
    Category: Build
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
