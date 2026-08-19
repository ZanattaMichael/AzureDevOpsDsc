# DSC AzDoTeam Resource

## Syntax

```PowerShell
AzDoTeam [string] #ResourceName
{
    ProjectName   = [String]$ProjectName
    TeamName      = [String]$TeamName
    [ Description = [String]$Description ]
    [ Ensure      = [String] {'Present', 'Absent'} ]
}
```

## Properties

### Common Properties

- **ProjectName**: The name of the Azure DevOps project. This property is mandatory and serves as a key property for the resource.
- **TeamName**: The name of the team. This is a key property.
- **Description**: An optional description for the team.
- **Ensure**: Specifies whether the team should exist. Valid values are `Present` and `Absent`.

## Additional Information

This resource manages teams within Azure DevOps projects. Teams group users together and can be assigned area paths and iterations for work item organization. Team members can be managed separately using the `AzDoTeamMember` resource.

## Examples

## Example 1: Sample Configuration using AzDoTeam Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    Node localhost {
        AzDoTeam AddTeam {
            Ensure      = 'Present'
            ProjectName = 'MyProject'
            TeamName    = 'Frontend Team'
            Description = 'Team responsible for frontend development'
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoTeam
$properties = @{
    ProjectName = 'MyProject'
    TeamName    = 'Frontend Team'
}

Invoke-DscResource -Name 'AzDoTeam' -Method Get -Property $properties -ModuleName 'AzureDevOpsDscNative'
```

## Example 3: Sample Configuration using Dsc.PipelineRunner

``` YAML
parameters: {}

variables: {
  ProjectName: MyProject
}

resources:
- name: Frontend Team
  type: AzureDevOpsDscNative/AzDoTeam
  dependsOn:
    - AzureDevOpsDscNative/AzDoProject/MyProject
  properties:
    ProjectName: $ProjectName
    TeamName: Frontend Team
    Description: Team responsible for frontend development
    Ensure: Present
```

Pipeline runner initialization:

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
