# AzDoProjectGroup Resource

## Description

The `AzDoProjectGroup` DSC resource is used to create and manage project-level groups within an Azure DevOps project. It allows you to define and enforce the desired state of groups that can be used for permission management and team organization at the project level.

## Syntax

```powershell
AzDoProjectGroup [string] #ResourceName
{
    GroupName = [String] $GroupName
    ProjectName = [String] $ProjectName
    [ GroupDescription = [String] $GroupDescription ]
    [ Ensure = [String] {'Present', 'Absent'} ]
    [ DependsOn = [String[]] ]
    [ PsDscRunAsCredential = [PSCredential] ]
}
```

## Properties

### Key Properties (Required)

- **GroupName** [String] - The name of the project group. This is the unique identifier for the group within the project.

- **ProjectName** [String] - The name of the Azure DevOps project that contains this group.

### Optional Properties

- **GroupDescription** [String] - A description for the project group. Provides context about the group's purpose and membership.

- **Ensure** [String] - Desired state of the resource:
  - `'Present'` - (default) Group should exist
  - `'Absent'` - Group should be removed

### Common Properties

- **DependsOn** [String[]] - Dependencies on other resources. Use this to control the order of resource execution.

- **PsDscRunAsCredential** [PSCredential] - Credentials to run this resource under.

## Return Values

The resource returns the following properties:

- **GroupName** - The name of the group
- **ProjectName** - The name of the project
- **GroupDescription** - The description of the group
- **Ensure** - Current state ('Present' or 'Absent')

## Examples

### Example 1: Create a Basic Project Group

```powershell
Configuration CreateProjectGroup {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoProjectGroup 'BackendTeam' {
            GroupName           = 'Backend Team'
            ProjectName         = 'MyProject'
            GroupDescription    = 'Group for backend development team members'
            Ensure              = 'Present'
        }
    }
}

CreateProjectGroup
Start-DscConfiguration -Path ./CreateProjectGroup -Wait -Verbose
```

### Example 2: Create Multiple Project Groups

```powershell
Configuration CreateMultipleProjectGroups {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoProjectGroup 'FrontendTeam' {
            GroupName           = 'Frontend Team'
            ProjectName         = 'MyProject'
            GroupDescription    = 'Group for frontend development team members'
            Ensure              = 'Present'
        }
        
        AzDoProjectGroup 'BackendTeam' {
            GroupName           = 'Backend Team'
            ProjectName         = 'MyProject'
            GroupDescription    = 'Group for backend development team members'
            Ensure              = 'Present'
        }
        
        AzDoProjectGroup 'QATeam' {
            GroupName           = 'QA Team'
            ProjectName         = 'MyProject'
            GroupDescription    = 'Group for quality assurance team members'
            Ensure              = 'Present'
        }
    }
}

CreateMultipleProjectGroups
Start-DscConfiguration -Path ./CreateMultipleProjectGroups -Wait -Verbose
```

### Example 3: Create Project Groups with Dependencies

```powershell
Configuration CreateProjectWithGroups {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoProject 'MyProject' {
            ProjectName        = 'MyProject'
            Ensure             = 'Present'
            SourceControlType  = 'Git'
            ProcessTemplate    = 'Agile'
        }
        
        AzDoProjectGroup 'Developers' {
            GroupName           = 'Developers'
            ProjectName         = 'MyProject'
            GroupDescription    = 'Development team group'
            Ensure              = 'Present'
            DependsOn           = '[AzDoProject]MyProject'
        }
        
        AzDoProjectGroup 'Leads' {
            GroupName           = 'Technical Leads'
            ProjectName         = 'MyProject'
            GroupDescription    = 'Technical leadership group'
            Ensure              = 'Present'
            DependsOn           = '[AzDoProject]MyProject'
        }
    }
}

CreateProjectWithGroups
Start-DscConfiguration -Path ./CreateProjectWithGroups -Wait -Verbose
```

### Example 4: Query Project Group State

```powershell
# Get the current state of a project group
$properties = @{
    GroupName   = 'Backend Team'
    ProjectName = 'MyProject'
}

$result = Invoke-DscResource -Name 'AzDoProjectGroup' `
    -Method Get `
    -Property $properties `
    -ModuleName 'AzureDevOpsDscNative'

$result | Select-Object GroupName, ProjectName, GroupDescription, Ensure
```

### Example 5: Update Project Group Description

```powershell
# Update a project group's description
$properties = @{
    GroupName           = 'Backend Team'
    ProjectName         = 'MyProject'
    GroupDescription    = 'Updated backend team description with new responsibilities'
    Ensure              = 'Present'
}

Invoke-DscResource -Name 'AzDoProjectGroup' `
    -Method Set `
    -Property $properties `
    -ModuleName 'AzureDevOpsDscNative'
```

### Example 6: Remove Project Group

```powershell
Configuration RemoveProjectGroup {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoProjectGroup 'RemoveOldGroup' {
            GroupName       = 'Old Team'
            ProjectName     = 'MyProject'
            Ensure          = 'Absent'
        }
    }
}

RemoveProjectGroup
Start-DscConfiguration -Path ./RemoveProjectGroup -Wait -Verbose
```

## Important Notes

### Group Naming

- Group names must be unique within the project
- Group names can include spaces and special characters
- Group names are case-sensitive for identification

### Project-Level Groups

- Groups created with this resource are scoped to the project level
- These groups can be used for project-specific permission assignments
- Use this resource in combination with permission resources for access control

### Group Management

- Removing a group also removes associated permissions
- Groups with active members should be migrated before removal
- Consider notifying team members before removing groups

## Troubleshooting

### Issue: "Group Already Exists"

**Cause**: A group with the same name already exists in the project

**Solution**:
```powershell
# Use a unique group name
# Or update the existing group instead of creating a new one
```

### Issue: "Cannot Create Group Due to Permissions"

**Cause**: Insufficient permissions for group management

**Solution**:
- Verify user has Project Administrator permissions
- Check personal access token has "Identity" scope
- Ensure user is in project administration group

### Issue: "Project Not Found"

**Cause**: The specified project does not exist

**Solution**:
```powershell
# Verify the project name matches exactly
# Ensure the project exists before attempting to create groups
# Use AzDoProject resource to create the project first
```

## Related Resources

- [AzDoProject](AzDoProject.md) - Create and manage Azure DevOps projects
- [AzDoGroupPermission](AzDoGroupPermission.md) - Manage group permissions
- [AzDoTeam](AzDoTeam.md) - Create teams in a project
- [AzDoPipelinePermission](AzDoPipelinePermission.md) - Manage pipeline permissions

## See Also

- [Azure DevOps Documentation](https://docs.microsoft.com/en-us/azure/devops/)
- [PowerShell DSC Documentation](https://docs.microsoft.com/en-us/powershell/dsc/overview)
- [AzureDevOpsDscNative Home](../Home.md)
