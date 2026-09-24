# DSC AzDoTeamMember Resource

## Syntax

```PowerShell
AzDoTeamMember [string] #ResourceName
{
    ProjectName   = [String]$ProjectName
    TeamName      = [String]$TeamName
    MemberName    = [String]$MemberName
    [ IsTeamAdmin = [Boolean]$IsTeamAdmin ]
    [ Ensure      = [String] {'Present', 'Absent'} ]
}
```

## Properties

### Common Properties

- **ProjectName**: The name of the Azure DevOps project. This property is mandatory and serves as a key property for the resource.
- **TeamName**: The name of the team. This is a key property.
- **MemberName**: The UPN, display name, or email of the user or group to add as a team member. This is a key property.
- **IsTeamAdmin**: Whether the member should hold team administrator rights (the "Manage membership" permission on the team's own security token). Defaults to `$false`. Revoked automatically when the member is removed from the team, regardless of this setting.
- **Ensure**: Specifies whether the team membership should exist. Valid values are `Present` and `Absent`.

## Additional Information

This resource manages membership of individual users or groups within a team. The team must already exist — use the `AzDoTeam` resource to create it first.

Setting `IsTeamAdmin = $true` grants the member the "Manage membership" permission on the
team's own token (`{ProjectId}\{TeamId}`) in the `Identity` security namespace, which is the
same right the "Team administrator" toggle grants in the Azure DevOps UI. Removing a member
always revokes this right first, whether or not `IsTeamAdmin` was ever set, so a removed
member is not left with admin rights over a team it no longer appears in.

## Examples

## Example 1: Sample Configuration using AzDoTeamMember Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    Node localhost {
        AzDoTeamMember AddTeamMember {
            Ensure      = 'Present'
            ProjectName = 'MyProject'
            TeamName    = 'Frontend Team'
            MemberName  = 'user@example.com'
            IsTeamAdmin = $true
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

Invoke-DscResource -Name 'AzDoTeamMember' -Method Get -Property $properties -ModuleName 'AzureDevOpsDscNative'
```

## Example 3: Sample Configuration using Dsc.PipelineRunner

``` YAML
parameters: {}

variables: {
  ProjectName: MyProject
}

resources:
- name: Frontend Team Member
  type: AzureDevOpsDscNative/AzDoTeamMember
  dependsOn:
    - AzureDevOpsDscNative/AzDoTeam/FrontendTeam
  properties:
    ProjectName: $ProjectName
    TeamName: Frontend Team
    MemberName: user@example.com
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
