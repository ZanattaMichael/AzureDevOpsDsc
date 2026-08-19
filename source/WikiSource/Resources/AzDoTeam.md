# AzDoTeam Resource

## Description

The `AzDoTeam` DSC resource is used to create and manage teams within Azure DevOps projects. Teams allow you to organize project members and define team-specific settings and security.

## Syntax

```powershell
AzDoTeam [string] #ResourceName
{
    TeamName = [String] $TeamName
    ProjectName = [String] $ProjectName
    [ Ensure = [String] {'Present', 'Absent'} ]
    [ TeamDescription = [String] $TeamDescription ]
    [ DependsOn = [String[]] ]
    [ PsDscRunAsCredential = [PSCredential] ]
}
```

## Properties

### Key Properties (Required)

- **TeamName** [String] - The name of the team to create or manage.

- **ProjectName** [String] - The name of the project where this team will be created.

### Optional Properties

- **Ensure** [String] - Desired state of the resource:
  - `'Present'` - (default) Team should exist
  - `'Absent'` - Team should be removed

- **TeamDescription** [String] - A description for the team that explains its purpose and responsibilities.

### Common Properties

- **DependsOn** [String[]] - Dependencies on other resources. Typically depends on the project existing first.

- **PsDscRunAsCredential** [PSCredential] - Credentials to run this resource under.

## Return Values

The resource returns the following properties:

- **TeamName** - The name of the team
- **ProjectName** - The project containing the team
- **Ensure** - Current state ('Present' or 'Absent')
- **TeamId** - The unique identifier of the team
- **TeamDescription** - The description of the team

## Examples

### Example 1: Create a Single Team

```powershell
Configuration CreateTeam {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        # First create the project
        AzDoProject 'MyProject' {
            Ensure              = 'Present'
            ProjectName         = 'MyProject'
            SourceControlType   = 'Git'
            ProcessTemplate     = 'Agile'
            Visibility          = 'Private'
        }
        
        # Then create the team
        AzDoTeam 'DevelopmentTeam' {
            Ensure              = 'Present'
            TeamName            = 'Development'
            ProjectName         = 'MyProject'
            TeamDescription     = 'Development team members'
            DependsOn           = '[AzDoProject]MyProject'
        }
    }
}

CreateTeam
Start-DscConfiguration -Path ./CreateTeam -Wait -Verbose
```

### Example 2: Create Multiple Teams

```powershell
Configuration CreateMultipleTeams {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoProject 'OrganizedProject' {
            Ensure              = 'Present'
            ProjectName         = 'OrganizedProject'
            SourceControlType   = 'Git'
            ProcessTemplate     = 'Agile'
            Visibility          = 'Private'
        }
        
        # Development team
        AzDoTeam 'DevTeam' {
            Ensure              = 'Present'
            TeamName            = 'Development'
            ProjectName         = 'OrganizedProject'
            TeamDescription     = 'Development team for coding'
            DependsOn           = '[AzDoProject]OrganizedProject'
        }
        
        # QA team
        AzDoTeam 'QATeam' {
            Ensure              = 'Present'
            TeamName            = 'QA'
            ProjectName         = 'OrganizedProject'
            TeamDescription     = 'Quality assurance team'
            DependsOn           = '[AzDoProject]OrganizedProject'
        }
        
        # DevOps team
        AzDoTeam 'DevOpsTeam' {
            Ensure              = 'Present'
            TeamName            = 'DevOps'
            ProjectName         = 'OrganizedProject'
            TeamDescription     = 'DevOps and infrastructure team'
            DependsOn           = '[AzDoProject]OrganizedProject'
        }
        
        # Management team
        AzDoTeam 'ManagementTeam' {
            Ensure              = 'Present'
            TeamName            = 'Management'
            ProjectName         = 'OrganizedProject'
            TeamDescription     = 'Project management team'
            DependsOn           = '[AzDoProject]OrganizedProject'
        }
    }
}

CreateMultipleTeams
Start-DscConfiguration -Path ./CreateMultipleTeams -Wait -Verbose
```

### Example 3: Create Teams with Members

```powershell
Configuration TeamsWithMembers {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoProject 'TeamProject' {
            Ensure              = 'Present'
            ProjectName         = 'TeamProject'
            SourceControlType   = 'Git'
            ProcessTemplate     = 'Scrum'
            Visibility          = 'Private'
        }
        
        # Create team
        AzDoTeam 'FrontendTeam' {
            Ensure              = 'Present'
            TeamName            = 'Frontend'
            ProjectName         = 'TeamProject'
            TeamDescription     = 'Frontend development team'
            DependsOn           = '[AzDoProject]TeamProject'
        }
        
        # Add team members
        AzDoTeamMember 'AddDeveloper1' {
            Ensure              = 'Present'
            TeamName            = 'Frontend'
            ProjectName         = 'TeamProject'
            MemberName          = 'alice@company.com'
            DependsOn           = '[AzDoTeam]FrontendTeam'
        }
        
        AzDoTeamMember 'AddDeveloper2' {
            Ensure              = 'Present'
            TeamName            = 'Frontend'
            ProjectName         = 'TeamProject'
            MemberName          = 'bob@company.com'
            DependsOn           = '[AzDoTeam]FrontendTeam'
        }
        
        AzDoTeamMember 'AddLead' {
            Ensure              = 'Present'
            TeamName            = 'Frontend'
            ProjectName         = 'TeamProject'
            MemberName          = 'charlie@company.com'
            DependsOn           = '[AzDoTeam]FrontendTeam'
        }
    }
}

TeamsWithMembers
Start-DscConfiguration -Path ./TeamsWithMembers -Wait -Verbose
```

### Example 4: Get Team Information

```powershell
# Retrieve team information
$properties = @{
    TeamName = 'Development'
    ProjectName = 'MyProject'
}

$result = Invoke-DscResource -Name 'AzDoTeam' `
    -Method Get `
    -Property $properties `
    -ModuleName 'AzureDevOpsDscNative'

Write-Host "Team Name: $($result.TeamName)"
Write-Host "Team ID: $($result.TeamId)"
Write-Host "Description: $($result.TeamDescription)"
```

### Example 5: Remove a Team

```powershell
Configuration RemoveTeam {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoTeam 'RemoveOldTeam' {
            Ensure      = 'Absent'
            TeamName    = 'OldTeam'
            ProjectName = 'MyProject'
        }
    }
}

RemoveTeam
Start-DscConfiguration -Path ./RemoveTeam -Wait -Verbose
```

### Example 6: Using Configuration Data

```powershell
# TeamsConfig.psd1
@{
    AllNodes = @(
        @{
            NodeName = 'localhost'
            ProjectName = 'MyProject'
            Teams = @(
                @{
                    Name = 'Development'
                    Description = 'Development team'
                },
                @{
                    Name = 'QA'
                    Description = 'Quality assurance'
                },
                @{
                    Name = 'DevOps'
                    Description = 'Infrastructure and DevOps'
                }
            )
        }
    )
}

# Configuration.ps1
Configuration CreateTeamsFromData {
    param([hashtable]$ConfigurationData)
    
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node $AllNodes.NodeName {
        foreach ($team in $Node.Teams) {
            AzDoTeam "Team_$($team.Name)" {
                Ensure          = 'Present'
                TeamName        = $team.Name
                ProjectName     = $Node.ProjectName
                TeamDescription = $team.Description
            }
        }
    }
}

$data = Import-PowerShellDataFile -Path TeamsConfig.psd1
CreateTeamsFromData -ConfigurationData $data
```

## Important Notes

### Team Naming

- Team names must be unique within a project
- Names are case-insensitive for identification
- Avoid special characters in team names

### Project Scope

- Teams always exist within the context of a project
- A team cannot exist without a project
- Always ensure the project exists before creating teams

### Default Teams

Some projects may have default teams created automatically:
- If these conflict with your configuration, you may need to rename them

### Team Permissions

After creating a team, you can:
- Add members using `AzDoTeamMember`
- Configure team settings using `AzDoTeamSettings`
- Assign permissions using permission resources

## Troubleshooting

### Issue: "Project Not Found"

**Cause**: The specified project doesn't exist

**Solution**:
```powershell
# Ensure the project is created first
DependsOn = '[AzDoProject]MyProject'
```

### Issue: "Team Already Exists"

**Cause**: A team with the same name already exists in the project

**Solution**:
- Use a unique team name
- Or ensure the existing team is removed first

### Issue: "Cannot Create Team Due to Permissions"

**Cause**: Authentication account lacks permissions to create teams

**Solution**:
- Verify user has project-level permissions
- Check Personal Access Token has appropriate scopes

## Related Resources

- [AzDoProject](AzDoProject) - Create and manage projects
- [AzDoTeamMember](../Resources/AzDoTeamMember) - Add members to teams
- [AzDoTeamSettings](../Resources/AzDoTeamSettings) - Configure team settings
- [AzDoProjectGroup](AzDoProjectGroup) - Manage project-level groups

## See Also

- [Azure DevOps Teams Documentation](https://docs.microsoft.com/en-us/azure/devops/organizations/settings/about-teams-and-settings)
- [AzureDevOpsDscNative Home](../Home)
