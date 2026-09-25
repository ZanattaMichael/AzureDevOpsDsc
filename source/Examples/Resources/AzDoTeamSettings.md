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
    [ BacklogVisibilities   = [Hashtable]$BacklogVisibilities ]
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
- **BacklogVisibilities**: A hashtable of backlog category reference names to a boolean, controlling which backlogs the team sees, for example `@{ 'Microsoft.EpicCategory' = $true; 'Microsoft.FeatureCategory' = $false }`. Only the categories the configuration states are compared; categories left out of the hashtable are never reported as drift. Accepting the backlog *behavior* name shown in the Azure DevOps UI (for example "Epics") as an alternative to the category reference name is not yet supported — see `docs/ResourceRoadmap.md`.
- **Ensure**: Specifies the desired state. This resource configures an existing team's settings and cannot be removed, so `Absent` is a no-op.

## Additional Information

This resource configures an existing Azure DevOps team's board/backlog settings: iteration and area paths, working days, bug behaviour, and which backlogs are visible to the team. The team itself is managed by the `AzDoTeam` resource. Because team settings cannot be deleted, `Ensure = 'Absent'` is treated as a no-op.

## Examples

## Example 1: Sample Configuration using AzDoTeamSettings Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

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
            BacklogVisibilities  = @{
                'Microsoft.EpicCategory'        = $true
                'Microsoft.FeatureCategory'     = $true
                'Microsoft.RequirementCategory' = $true
            }
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

Invoke-DscResource -Name 'AzDoTeamSettings' -Method Get -Property $properties -ModuleName 'AzureDevOpsDscNative'
```

## Example 3: Sample Configuration using Dsc.PipelineRunner

``` YAML
parameters: {}

variables: {
  ProjectName: MyProject,
  TeamName: MyProject Team
}

resources:
- name: Configure Team Settings
  type: AzureDevOpsDscNative/AzDoTeamSettings
  dependsOn:
    - AzureDevOpsDscNative/AzDoTeam/MyProject Team
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
