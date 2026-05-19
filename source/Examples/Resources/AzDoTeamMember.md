# DSC AzDoTeamMember Resource

## Syntax

```PowerShell
AzDoTeamMember [string] #ResourceName
{
    ProjectName = [String]$ProjectName
    TeamName    = [String]$TeamName
    MemberName  = [String]$MemberName
    [ Ensure    = [String] {'Present', 'Absent'} ]
}
```

## Properties

### Common Properties

- **ProjectName**: The name of the Azure DevOps project. This property is mandatory and serves as a key property for the resource.
- **TeamName**: The name of the team. This is a key property.
- **MemberName**: The UPN, display name, or email of the user or group to add as a team member. This is a key property.
- **Ensure**: Specifies whether the team membership should exist. Valid values are `Present` and `Absent`.

## Additional Information

This resource manages membership of individual users or groups within a team. The team must already exist — use the `AzDoTeam` resource to create it first.

## Examples

## Example 1: Sample Configuration using AzDoTeamMember Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoTeamMember AddTeamMember {
            Ensure      = 'Present'
            ProjectName = 'MyProject'
            TeamName    = 'Frontend Team'
            MemberName  = 'user@example.com'
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoTeamMember
$properties = @{
    ProjectName = 'MyProject'
    TeamName    = 'Frontend Team'
    MemberName  = 'user@example.com'
}

Invoke-DscResource -Name 'AzDoTeamMember' -Method Get -Property $properties -ModuleName 'AzureDevOpsDsc'
```

## Example 3: Sample Configuration using AzDO-DSC-LCM

``` YAML
parameters: {}

variables: {
  ProjectName: MyProject
}

resources:
- name: Frontend Team Member
  type: AzureDevOpsDsc/AzDoTeamMember
  dependsOn:
    - AzureDevOpsDsc/AzDoTeam/FrontendTeam
  properties:
    ProjectName: $ProjectName
    TeamName: Frontend Team
    MemberName: user@example.com
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
