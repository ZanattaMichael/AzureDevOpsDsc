# AzDoAreaNodes Resource

## Description

The `AzDoAreaNodes` DSC resource is used to manage area nodes (also called area paths) within an Azure DevOps project. Areas are used to organize and track work items by functional areas or teams, enabling better categorization and filtering of work across the project.

## Syntax

```powershell
AzDoAreaNodes [string] #ResourceName
{
    ProjectName = [String] $ProjectName
    [ AreaPaths = [String[]] $AreaPaths ]
    [ Ensure = [String] {'Present', 'Absent'} ]
    [ DependsOn = [String[]] ]
    [ PsDscRunAsCredential = [PSCredential] ]
}
```

## Properties

### Key Properties (Required)

- **ProjectName** [String] - The name of the Azure DevOps project.

### Optional Properties

- **AreaPaths** [String[]] - An array of area path strings to create or manage (e.g., @('Frontend', 'Backend', 'DevOps')).

- **Ensure** [String] - Desired state of the resource:
  - `'Present'` - (default) Area paths should exist
  - `'Absent'` - Area paths should be removed

### Common Properties

- **DependsOn** [String[]] - Dependencies on other resources. Use this to control the order of resource execution.

- **PsDscRunAsCredential** [PSCredential] - Credentials to run this resource under.

## Return Values

The resource returns the following properties:

- **ProjectName** - The name of the project
- **AreaPaths** - The list of area paths that exist or are configured
- **Ensure** - Current state ('Present' or 'Absent')

## Examples

### Example 1: Create Basic Area Structure

```powershell
Configuration CreateBasicAreas {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoAreaNodes 'ProjectAreas' {
            ProjectName = 'MyProject'
            AreaPaths   = @(
                'Frontend',
                'Backend',
                'DevOps',
                'Documentation'
            )
            Ensure = 'Present'
        }
    }
}

CreateBasicAreas
Start-DscConfiguration -Path ./CreateBasicAreas -Wait -Verbose
```

### Example 2: Create Hierarchical Area Structure

```powershell
Configuration CreateHierarchicalAreas {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoAreaNodes 'TeamAreas' {
            ProjectName = 'MyProject'
            AreaPaths   = @(
                'Platform',
                'Platform\Backend',
                'Platform\Backend\APIs',
                'Platform\Backend\Services',
                'Platform\Frontend',
                'Platform\Frontend\Web',
                'Platform\Frontend\Mobile'
            )
            Ensure = 'Present'
        }
    }
}

CreateHierarchicalAreas
Start-DscConfiguration -Path ./CreateHierarchicalAreas -Wait -Verbose
```

### Example 3: Create Organizational Area Structure

```powershell
Configuration OrganizationalAreas {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoAreaNodes 'OrgAreas' {
            ProjectName = 'EnterprisePlatform'
            AreaPaths   = @(
                'Engineering\Development',
                'Engineering\QA',
                'Engineering\DevOps',
                'Infrastructure\Cloud',
                'Infrastructure\On-Premises',
                'Operations\Support',
                'Operations\Monitoring'
            )
            Ensure = 'Present'
        }
    }
}

OrganizationalAreas
Start-DscConfiguration -Path ./OrganizationalAreas -Wait -Verbose
```

### Example 4: Query Current Area Structure

```powershell
# Get the current state of areas
$properties = @{
    ProjectName = 'MyProject'
}

$result = Invoke-DscResource -Name 'AzDoAreaNodes' `
    -Method Get `
    -Property $properties `
    -ModuleName 'AzureDevOpsDscNative'

$result | Select-Object ProjectName, AreaPaths, Ensure
```

### Example 5: Create Areas with Dependencies

```powershell
Configuration CreateProjectWithAreas {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoProject 'MyProject' {
            ProjectName       = 'MyProject'
            Ensure            = 'Present'
            SourceControlType = 'Git'
            ProcessTemplate   = 'Agile'
        }
        
        AzDoAreaNodes 'ProjectAreas' {
            ProjectName = 'MyProject'
            AreaPaths   = @(
                'Frontend',
                'Backend',
                'QA',
                'DevOps'
            )
            Ensure      = 'Present'
            DependsOn   = '[AzDoProject]MyProject'
        }
    }
}

CreateProjectWithAreas
Start-DscConfiguration -Path ./CreateProjectWithAreas -Wait -Verbose
```

### Example 6: Update Existing Area Structure

```powershell
Configuration UpdateAreaStructure {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoAreaNodes 'UpdatedAreas' {
            ProjectName = 'MyProject'
            AreaPaths   = @(
                'Frontend',
                'Backend',
                'Backend\APIs',
                'Backend\Services',
                'QA',
                'DevOps',
                'Security'
            )
            Ensure = 'Present'
        }
    }
}

UpdateAreaStructure
Start-DscConfiguration -Path ./UpdateAreaStructure -Wait -Verbose
```

### Example 7: Remove Specific Areas

```powershell
Configuration RemoveAreas {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoAreaNodes 'RemoveUnused' {
            ProjectName = 'MyProject'
            AreaPaths   = @('LegacyArea', 'DeprecatedArea')
            Ensure      = 'Absent'
        }
    }
}

RemoveAreas
Start-DscConfiguration -Path ./RemoveAreas -Wait -Verbose
```

## Important Notes

### Area Paths

- Area paths use backslash as separator (e.g., 'Parent\Child')
- Paths are case-insensitive for matching but case-sensitive for display
- Path depth is typically limited by project settings

### Area Hierarchy

- Areas form a tree structure within the project
- Child areas inherit permissions from parents
- Areas can be used for organizing work items and permissions

### Best Practices

- Plan area structure early in project setup
- Use meaningful names that reflect organizational structure
- Keep hierarchy reasonably flat (2-3 levels deep)
- Document area purposes for team members

### Area Management

- Creating areas does not affect existing work items
- Removing areas may require reassigning work items first
- Areas are commonly used with iterations for sprint planning

## Troubleshooting

### Issue: "Project Not Found"

**Cause**: The specified project does not exist

**Solution**:
```powershell
# Verify the project name matches exactly
# Ensure the project exists before creating areas
# Use AzDoProject resource to create the project first
```

### Issue: "Cannot Create Area Path"

**Cause**: Invalid path format or parent area doesn't exist

**Solution**:
- Verify path format uses backslash as separator
- Ensure parent areas exist before creating child areas
- Check for special characters in area names

### Issue: "Areas Not Appearing in Work Item Dropdowns"

**Cause**: Caching or incomplete configuration

**Solution**:
```powershell
# Refresh the work item tracking database
# Reload Azure DevOps UI in browser
# Verify areas were created successfully
```

## Related Resources

- [AzDoProject](AzDoProject) - Create and manage Azure DevOps projects
- [AzDoAreaPermission](AzDoAreaPermission) - Manage area-level permissions
- [AzDoIterationNodes](AzDoIterationNodes) - Manage iteration nodes (sprints)
- [AzDoWIPTags](AzDoWIPTags) - Configure work-in-progress tags

## See Also

- [Azure DevOps Documentation](https://docs.microsoft.com/en-us/azure/devops/)
- [PowerShell DSC Documentation](https://docs.microsoft.com/en-us/powershell/dsc/overview)
- [AzureDevOpsDscNative Home](../Home)
