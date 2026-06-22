# DSC AzDoTeamSettings Resource

## Syntax

```PowerShell
AzDoTeamSettings [string] #ResourceName
{
    ProjectName              = [String]$ProjectName
    TeamName                 = [String]$TeamName
    [ BacklogIterationPath  = [String]$BacklogIterationPath ]
    [ DefaultIterationPath  = [String]$DefaultIterationPath ]
    [ IterationPaths        = [String[]]$IterationPaths ]
    [ DefaultAreaPath       = [String]$DefaultAreaPath ]
    [ AreaPaths             = [String[]]$AreaPaths ]
    [ WorkingDays           = [String[]]$WorkingDays ]
    [ BugsBehavior          = [String] {'asRequirements', 'asTasks', 'off'} ]
    [ Ensure                = [String] {'Present', 'Absent'} ]
}
```

## Properties

### Common Properties

- **ProjectName**: The name of the Azure DevOps project. This property is mandatory and serves as the key property for the resource.
- **TeamName**: The name of the team whose settings are managed. This property is mandatory.
- **BacklogIterationPath**: The backlog iteration path for the team.
- **DefaultIterationPath**: The default iteration path for new work items.
- **IterationPaths**: The iteration paths selected for the team.
- **DefaultAreaPath**: The default area path for the team.
- **AreaPaths**: The area paths assigned to the team.
- **WorkingDays**: The team's working days, for example `@('monday','tuesday','wednesday','thursday','friday')`.
- **BugsBehavior**: How bugs are shown on backlogs and boards. Valid values are `asRequirements`, `asTasks` and `off`.
- **Ensure**: Specifies the desired state. This resource configures an existing team's settings and cannot be removed, so `Absent` is a no-op.

## Additional Information

This resource configures an existing Azure DevOps team's board/backlog settings: iteration and area paths, working days, and bug behaviour. The team itself is managed by the `AzDoTeam` resource. Because team settings cannot be deleted, `Ensure = 'Absent'` is treated as a no-op.

## Examples

## Example 1: Sample Configuration using AzDoTeamSettings Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoTeamSettings ConfigureTeam {
            Ensure               = 'Present'
            ProjectName          = 'MyProject'
            TeamName             = 'MyProject Team'
            BacklogIterationPath = 'MyProject'
            DefaultIterationPath = 'MyProject\Sprint 1'
            IterationPaths       = @('MyProject\Sprint 1', 'MyProject\Sprint 2')
            DefaultAreaPath      = 'MyProject'
            AreaPaths            = @('MyProject')
            WorkingDays          = @('monday', 'tuesday', 'wednesday', 'thursday', 'friday')
            BugsBehavior         = 'asRequirements'
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoTeamSettings
$properties = @{
    ProjectName = 'MyProject'
    TeamName    = 'MyProject Team'
}

Invoke-DscResource -Name 'AzDoTeamSettings' -Method Get -Property $properties -ModuleName 'AzureDevOpsDsc'
```

## Example 3: Sample Configuration using AzDO-DSC-LCM

``` YAML
parameters: {}

variables: {
  ProjectName: MyProject,
  TeamName: MyProject Team
}

resources:
- name: Configure Team Settings
  type: AzureDevOpsDsc/AzDoTeamSettings
  dependsOn:
    - AzureDevOpsDsc/AzDoTeam/MyProject Team
  properties:
    ProjectName: $ProjectName
    TeamName: $TeamName
    BacklogIterationPath: $ProjectName
    DefaultIterationPath: $ProjectName\Sprint 1
    IterationPaths:
      - $ProjectName\Sprint 1
      - $ProjectName\Sprint 2
    DefaultAreaPath: $ProjectName
    AreaPaths:
      - $ProjectName
    WorkingDays:
      - monday
      - tuesday
      - wednesday
      - thursday
      - friday
    BugsBehavior: asRequirements
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
