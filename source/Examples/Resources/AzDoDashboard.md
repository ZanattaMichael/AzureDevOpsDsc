# DSC AzDoDashboard Resource

## Syntax

```PowerShell
AzDoDashboard [string] #ResourceName
{
    DashboardName          = [String]$DashboardName
    ProjectName            = [String]$ProjectName
    [ TeamName             = [String]$TeamName ]
    [ Description          = [String]$Description ]
    [ RefreshInterval      = [Int32]$RefreshInterval ]
    [ Ensure               = [String] {'Present', 'Absent'} ]
}
```

## Properties

### Common Properties

- **DashboardName**: The name of the dashboard. This is the key property, unique within its team or project.
- **ProjectName**: The name of the Azure DevOps project. Mandatory.
- **TeamName**: The team that owns the dashboard, for example `'MyProject Team'`. Omit it for a project-scoped dashboard.
- **Description**: A description of the dashboard. Left unmanaged when not specified.
- **RefreshInterval**: The automatic refresh interval in minutes; `0` turns automatic refresh off. The service decides which intervals it accepts - the web UI offers off and 5 minutes. Left unmanaged when not specified.
- **Ensure**: Specifies whether the dashboard should exist. Valid values are `Present` and `Absent`.

## Additional Information

The resource manages the dashboard itself, not the widgets on it. Widgets added in the UI are kept on every update, and removing the dashboard removes its widgets with it.

The dashboard name is the key, so renaming a dashboard in the configuration creates a new dashboard rather than renaming the existing one. It also means a configuration can declare a given dashboard name only once, even for different teams.

Only the settings a configuration states are compared. Because the API replaces a dashboard's settings on every update, a setting the configuration does not state is written back with its current value rather than cleared.

## Examples

## Example 1: Sample Configuration using AzDoDashboard Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    Node localhost {
        AzDoDashboard SprintOverview {
            Ensure          = 'Present'
            DashboardName   = 'Sprint Overview'
            ProjectName     = 'MyProject'
            TeamName        = 'MyProject Team'
            Description     = 'Burndown and open bugs for the current sprint'
            RefreshInterval = 5
        }

        AzDoDashboard ProjectHealth {
            Ensure        = 'Present'
            DashboardName = 'Project Health'
            ProjectName   = 'MyProject'
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoDashboard
$properties = @{
    DashboardName = 'Sprint Overview'
    ProjectName   = 'MyProject'
    TeamName      = 'MyProject Team'
}

Invoke-DscResource -Name 'AzDoDashboard' -Method Get -Property $properties -ModuleName 'AzureDevOpsDscNative'
```

## Example 3: Sample Configuration using Dsc.PipelineRunner

``` YAML
parameters: {}

variables: {
  ProjectName: MyProject
}

resources:
- name: Sprint Overview Dashboard
  type: AzureDevOpsDscNative/AzDoDashboard
  dependsOn:
    - AzureDevOpsDscNative/AzDoProject/MyProject
  properties:
    DashboardName: Sprint Overview
    ProjectName: $ProjectName
    TeamName: MyProject Team
    Description: Burndown and open bugs for the current sprint
    RefreshInterval: 5
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
