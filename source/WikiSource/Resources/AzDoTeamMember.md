# AzDoTeamMember Resource

## Description

The `AzDoTeamMember` DSC resource is used to add or remove members from an Azure DevOps team within a project. It allows you to define and enforce the desired state of team membership, ensuring the correct users are part of specific teams.

## Syntax

```powershell
AzDoTeamMember [string] #ResourceName
{
    ProjectName = [String] $ProjectName
    TeamName = [String] $TeamName
    MemberName = [String] $MemberName
    [ Ensure = [String] {'Present', 'Absent'} ]
    [ DependsOn = [String[]] ]
    [ PsDscRunAsCredential = [PSCredential] ]
}
```

## Properties

### Key Properties (Required)

- **ProjectName** [String] - The name of the Azure DevOps project that contains the team.

- **TeamName** [String] - The name of the team within the project.

- **MemberName** [String] - The name or email of the user to add or remove from the team.

### Optional Properties

- **Ensure** [String] - Desired state of the resource:
  - `'Present'` - (default) User should be a member of the team
  - `'Absent'` - User should be removed from the team

### Common Properties

- **DependsOn** [String[]] - Dependencies on other resources. Use this to control the order of resource execution.

- **PsDscRunAsCredential** [PSCredential] - Credentials to run this resource under.

## Return Values

The resource returns the following properties:

- **ProjectName** - The name of the project
- **TeamName** - The name of the team
- **MemberName** - The name of the team member
- **Ensure** - Current state ('Present' or 'Absent')

## Examples

### Example 1: Add a Member to a Team

```powershell
Configuration AddTeamMember {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoTeamMember 'AddDeveloper' {
            ProjectName = 'MyProject'
            TeamName    = 'Backend Team'
            MemberName  = 'john.doe@company.com'
            Ensure      = 'Present'
        }
    }
}

AddTeamMember
Start-DscConfiguration -Path ./AddTeamMember -Wait -Verbose
```

### Example 2: Add Multiple Members to Team

```powershell
Configuration AddMultipleMembers {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoTeamMember 'AddDeveloper1' {
            ProjectName = 'MyProject'
            TeamName    = 'Development Team'
            MemberName  = 'alice.smith@company.com'
            Ensure      = 'Present'
        }
        
        AzDoTeamMember 'AddDeveloper2' {
            ProjectName = 'MyProject'
            TeamName    = 'Development Team'
            MemberName  = 'bob.johnson@company.com'
            Ensure      = 'Present'
        }
        
        AzDoTeamMember 'AddQA' {
            ProjectName = 'MyProject'
            TeamName    = 'QA Team'
            MemberName  = 'charlie.brown@company.com'
            Ensure      = 'Present'
        }
    }
}

AddMultipleMembers
Start-DscConfiguration -Path ./AddMultipleMembers -Wait -Verbose
```

### Example 3: Create Team with Members

```powershell
Configuration CreateTeamWithMembers {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoTeam 'BackendTeam' {
            ProjectName         = 'MyProject'
            TeamName            = 'Backend Team'
            TeamDescription     = 'Backend development team'
            Ensure              = 'Present'
        }
        
        AzDoTeamMember 'Lead' {
            ProjectName = 'MyProject'
            TeamName    = 'Backend Team'
            MemberName  = 'lead@company.com'
            Ensure      = 'Present'
            DependsOn   = '[AzDoTeam]BackendTeam'
        }
        
        AzDoTeamMember 'Developer1' {
            ProjectName = 'MyProject'
            TeamName    = 'Backend Team'
            MemberName  = 'dev1@company.com'
            Ensure      = 'Present'
            DependsOn   = '[AzDoTeam]BackendTeam'
        }
        
        AzDoTeamMember 'Developer2' {
            ProjectName = 'MyProject'
            TeamName    = 'Backend Team'
            MemberName  = 'dev2@company.com'
            Ensure      = 'Present'
            DependsOn   = '[AzDoTeam]BackendTeam'
        }
    }
}

CreateTeamWithMembers
Start-DscConfiguration -Path ./CreateTeamWithMembers -Wait -Verbose
```

### Example 4: Query Team Membership

```powershell
# Get the current state of team membership
$properties = @{
    ProjectName = 'MyProject'
    TeamName    = 'Development Team'
    MemberName  = 'alice.smith@company.com'
}

$result = Invoke-DscResource -Name 'AzDoTeamMember' `
    -Method Get `
    -Property $properties `
    -ModuleName 'AzureDevOpsDscNative'

$result | Select-Object ProjectName, TeamName, MemberName, Ensure
```

### Example 5: Remove Member from Team

```powershell
Configuration RemoveTeamMember {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoTeamMember 'RemoveFormer' {
            ProjectName = 'MyProject'
            TeamName    = 'Development Team'
            MemberName  = 'former.employee@company.com'
            Ensure      = 'Absent'
        }
    }
}

RemoveTeamMember
Start-DscConfiguration -Path ./RemoveTeamMember -Wait -Verbose
```

## Important Notes

### Member Identification

- Members should be identified by their email address or user principal name
- Ensure the email format matches the organization's Azure AD/AAD configuration
- The user must exist in the organization before adding to a team

### Team Requirements

- The team must exist before adding members
- Use the AzDoTeam resource to create teams first
- Members inherit team permissions automatically

### Bulk Operations

- To add multiple members, create multiple AzDoTeamMember resources
- Use DependsOn to control order if team creation and member addition need sequencing

## Troubleshooting

### Issue: "User Not Found"

**Cause**: The specified user does not exist in the organization

**Solution**:
```powershell
# Verify the user exists in Azure DevOps organization
# Check the email format matches the organization's configuration
# Ensure the user has been invited to the organization
```

### Issue: "Cannot Add Member to Team"

**Cause**: Insufficient permissions or team does not exist

**Solution**:
- Verify the team exists using AzDoTeam resource
- Check that the personal access token has "Member Entitlement Management" scope
- Ensure the user has project-level permissions

### Issue: "User Already Member"

**Cause**: The user is already a member of the team

**Solution**:
```powershell
# This is not an error state; the resource will report as compliant
# No action is needed if the user is already in the team
```

## Related Resources

- [AzDoTeam](AzDoTeam) - Create and manage teams within projects
- [AzDoProject](AzDoProject) - Create and manage Azure DevOps projects
- [AzDoGroupMember](AzDoGroupMember) - Add members to organization groups
- [AzDoTeamSettings](AzDoTeamSettings) - Configure team settings

## See Also

- [Azure DevOps Documentation](https://docs.microsoft.com/en-us/azure/devops/)
- [PowerShell DSC Documentation](https://docs.microsoft.com/en-us/powershell/dsc/overview)
- [AzureDevOpsDscNative Home](../Home)
