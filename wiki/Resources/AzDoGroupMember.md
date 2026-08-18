# AzDoGroupMember Resource

## Description

The `AzDoGroupMember` DSC resource manages membership within Azure DevOps groups (both organization and project-level). It allows you to add or remove users and other identities from groups.

## Syntax

```powershell
AzDoGroupMember [string] #ResourceName
{
    GroupName = [String] $GroupName
    MemberName = [String] $MemberName
    [ ProjectName = [String] $ProjectName ]
    [ Ensure = [String] {'Present', 'Absent'} ]
    [ DependsOn = [String[]] ]
    [ PsDscRunAsCredential = [PSCredential] ]
}
```

## Properties

### Key Properties (Required)

- **GroupName** [String] - The name of the group to manage membership for.

- **MemberName** [String] - The name or email of the member to add or remove.

### Optional Properties

- **ProjectName** [String] - The project name for project-level groups. Omit for organization-level groups.

- **Ensure** [String] - Desired state:
  - `'Present'` - (default) Member should be in the group
  - `'Absent'` - Member should be removed from the group

### Common Properties

- **DependsOn** [String[]] - Dependencies on other resources.

- **PsDscRunAsCredential** [PSCredential] - Credentials to run this resource under.

## Return Values

- **GroupName** - The group name
- **MemberName** - The member name/email
- **ProjectName** - The project (if project-level)
- **Ensure** - Current state

## Examples

### Example 1: Add Member to Organization Group

```powershell
Configuration AddOrgMember {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoOrganizationGroup 'DevGroup' {
            Ensure          = 'Present'
            GroupName       = 'Developers'
        }
        
        AzDoGroupMember 'AddDev1' {
            Ensure      = 'Present'
            GroupName   = 'Developers'
            MemberName  = 'developer1@company.com'
            DependsOn   = '[AzDoOrganizationGroup]DevGroup'
        }
    }
}

AddOrgMember
Start-DscConfiguration -Path ./AddOrgMember -Wait -Verbose
```

### Example 2: Add Multiple Members to Group

```powershell
Configuration AddMultipleMembers {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoOrganizationGroup 'AdminGroup' {
            Ensure          = 'Present'
            GroupName       = 'Administrators'
        }
        
        AzDoGroupMember 'AddAdmin1' {
            Ensure      = 'Present'
            GroupName   = 'Administrators'
            MemberName  = 'admin1@company.com'
            DependsOn   = '[AzDoOrganizationGroup]AdminGroup'
        }
        
        AzDoGroupMember 'AddAdmin2' {
            Ensure      = 'Present'
            GroupName   = 'Administrators'
            MemberName  = 'admin2@company.com'
            DependsOn   = '[AzDoOrganizationGroup]AdminGroup'
        }
    }
}

AddMultipleMembers
Start-DscConfiguration -Path ./AddMultipleMembers -Wait -Verbose
```

### Example 3: Add Member to Project Group

```powershell
Configuration AddProjectMember {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoProject 'MyProject' {
            Ensure              = 'Present'
            ProjectName         = 'MyProject'
            SourceControlType   = 'Git'
            ProcessTemplate     = 'Agile'
        }
        
        AzDoProjectGroup 'ProjectDevs' {
            Ensure              = 'Present'
            ProjectName         = 'MyProject'
            GroupName           = 'Project Developers'
            DependsOn           = '[AzDoProject]MyProject'
        }
        
        AzDoGroupMember 'AddProjectMember' {
            Ensure      = 'Present'
            GroupName   = 'Project Developers'
            ProjectName = 'MyProject'
            MemberName  = 'developer@company.com'
            DependsOn   = '[AzDoProjectGroup]ProjectDevs'
        }
    }
}

AddProjectMember
Start-DscConfiguration -Path ./AddProjectMember -Wait -Verbose
```

### Example 4: Remove Member from Group

```powershell
Configuration RemoveMember {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoGroupMember 'RemoveMember' {
            Ensure      = 'Absent'
            GroupName   = 'Developers'
            MemberName  = 'old.employee@company.com'
        }
    }
}

RemoveMember
Start-DscConfiguration -Path ./RemoveMember -Wait -Verbose
```

## Important Notes

### Member Identification

Members can be identified by:
- Email address (recommended)
- Username
- Display name (less reliable)

### Project vs Organization Groups

- Omit `ProjectName` for organization-level groups
- Include `ProjectName` for project-level groups
- Use appropriate group scope for your scenario

### Group Dependency

Always ensure the group exists before adding members:
```powershell
DependsOn = '[AzDoOrganizationGroup]GroupName'
```

## Troubleshooting

### Issue: "Member Not Found"

**Cause**: Member doesn't exist in the organization or project

**Solution**:
- Verify the member's email/username
- Ensure the member is a valid Azure DevOps user
- Check if the member is already added

### Issue: "Cannot Add Member to Group"

**Cause**: Permissions issue or group not found

**Solution**:
- Verify group exists first
- Check that authentication has appropriate permissions
- Ensure proper group scope (org vs project)

## Related Resources

- [AzDoOrganizationGroup](AzDoOrganizationGroup.md) - Create organization groups
- [AzDoProjectGroup](AzDoProjectGroup.md) - Create project groups
- [AzDoTeamMember](AzDoTeamMember.md) - Manage team membership
- [AzDoGroupPermission](AzDoGroupPermission.md) - Manage group permissions

## See Also

- [Azure DevOps Groups Documentation](https://docs.microsoft.com/en-us/azure/devops/organizations/security/about-security-identity)
- [AzureDevOpsDscNative Home](../Home.md)
