# AzDoIterationNodes Resource

## Description

The `AzDoIterationNodes` DSC resource is used to manage iteration nodes (sprints and release cycles) within an Azure DevOps project. Iterations are used for time-based work planning and are essential for agile and scrum-based project management. This resource allows you to create, configure, and manage iteration hierarchies with specific dates and attributes.

## Syntax

```powershell
AzDoIterationNodes [string] #ResourceName
{
    ProjectName = [String] $ProjectName
    [ IterationAttributes = [HashTable[]] $IterationAttributes ]
    [ Ensure = [String] {'Present', 'Absent'} ]
    [ DependsOn = [String[]] ]
    [ PsDscRunAsCredential = [PSCredential] ]
}
```

## Properties

### Key Properties (Required)

- **ProjectName** [String] - The name of the Azure DevOps project.

### Optional Properties

- **IterationAttributes** [HashTable[]] - An array of hashtables, each containing iteration attributes:
  - `Path` - The iteration path (e.g., 'Sprint 1', 'Release 2024')
  - `StartDate` - The start date of the iteration (format: 'YYYY-MM-DD')
  - `EndDate` - The end date of the iteration (format: 'YYYY-MM-DD')

- **Ensure** [String] - Desired state of the resource:
  - `'Present'` - (default) Iterations should exist
  - `'Absent'` - Iterations should be removed

### Common Properties

- **DependsOn** [String[]] - Dependencies on other resources. Use this to control the order of resource execution.

- **PsDscRunAsCredential** [PSCredential] - Credentials to run this resource under.

## Return Values

The resource returns the following properties:

- **ProjectName** - The name of the project
- **IterationAttributes** - The configured iteration attributes
- **Ensure** - Current state ('Present' or 'Absent')

## Examples

### Example 1: Create Simple Sprint Structure

```powershell
Configuration CreateSprints {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoIterationNodes 'ProjectSprints' {
            ProjectName         = 'MyProject'
            IterationAttributes = @(
                @{
                    Path      = 'Sprint 1'
                    StartDate = '2024-01-01'
                    EndDate   = '2024-01-14'
                },
                @{
                    Path      = 'Sprint 2'
                    StartDate = '2024-01-15'
                    EndDate   = '2024-01-28'
                },
                @{
                    Path      = 'Sprint 3'
                    StartDate = '2024-01-29'
                    EndDate   = '2024-02-11'
                }
            )
            Ensure = 'Present'
        }
    }
}

CreateSprints
Start-DscConfiguration -Path ./CreateSprints -Wait -Verbose
```

### Example 2: Create Hierarchical Iteration Structure

```powershell
Configuration CreateHierarchicalIterations {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoIterationNodes 'ReleaseIterations' {
            ProjectName         = 'MyProject'
            IterationAttributes = @(
                @{
                    Path      = 'Release 2024'
                    StartDate = '2024-01-01'
                    EndDate   = '2024-12-31'
                },
                @{
                    Path      = 'Release 2024\Q1'
                    StartDate = '2024-01-01'
                    EndDate   = '2024-03-31'
                },
                @{
                    Path      = 'Release 2024\Q1\Sprint 1'
                    StartDate = '2024-01-01'
                    EndDate   = '2024-01-14'
                },
                @{
                    Path      = 'Release 2024\Q1\Sprint 2'
                    StartDate = '2024-01-15'
                    EndDate   = '2024-02-11'
                }
            )
            Ensure = 'Present'
        }
    }
}

CreateHierarchicalIterations
Start-DscConfiguration -Path ./CreateHierarchicalIterations -Wait -Verbose
```

### Example 3: Create Multi-Year Iteration Plan

```powershell
Configuration MultiYearPlan {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoIterationNodes 'LongTermPlan' {
            ProjectName         = 'EnterprisePlatform'
            IterationAttributes = @(
                @{
                    Path      = '2024\Q1\Sprint 1'
                    StartDate = '2024-01-01'
                    EndDate   = '2024-01-14'
                },
                @{
                    Path      = '2024\Q1\Sprint 2'
                    StartDate = '2024-01-15'
                    EndDate   = '2024-02-11'
                },
                @{
                    Path      = '2024\Q2\Sprint 3'
                    StartDate = '2024-04-01'
                    EndDate   = '2024-04-14'
                },
                @{
                    Path      = '2024\Q2\Sprint 4'
                    StartDate = '2024-04-15'
                    EndDate   = '2024-05-12'
                },
                @{
                    Path      = '2025\Q1\Sprint 1'
                    StartDate = '2025-01-01'
                    EndDate   = '2025-01-14'
                }
            )
            Ensure = 'Present'
        }
    }
}

MultiYearPlan
Start-DscConfiguration -Path ./MultiYearPlan -Wait -Verbose
```

### Example 4: Query Current Iteration Configuration

```powershell
# Get the current state of iterations
$properties = @{
    ProjectName = 'MyProject'
}

$result = Invoke-DscResource -Name 'AzDoIterationNodes' `
    -Method Get `
    -Property $properties `
    -ModuleName 'AzureDevOpsDscNative'

$result | Select-Object ProjectName, IterationAttributes, Ensure
```

### Example 5: Create Project with Iterations

```powershell
Configuration ProjectWithIterations {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoProject 'MyProject' {
            ProjectName       = 'MyProject'
            Ensure            = 'Present'
            SourceControlType = 'Git'
            ProcessTemplate   = 'Scrum'
        }
        
        AzDoIterationNodes 'ProjectIterations' {
            ProjectName         = 'MyProject'
            IterationAttributes = @(
                @{
                    Path      = 'Sprint 1'
                    StartDate = '2024-01-01'
                    EndDate   = '2024-01-14'
                },
                @{
                    Path      = 'Sprint 2'
                    StartDate = '2024-01-15'
                    EndDate   = '2024-02-11'
                }
            )
            Ensure = 'Present'
            DependsOn = '[AzDoProject]MyProject'
        }
    }
}

ProjectWithIterations
Start-DscConfiguration -Path ./ProjectWithIterations -Wait -Verbose
```

### Example 6: Manage Multiple Project Iterations

```powershell
Configuration MultiProjectIterations {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoIterationNodes 'WebProjectIterations' {
            ProjectName         = 'WebApplication'
            IterationAttributes = @(
                @{
                    Path      = 'Sprint 1'
                    StartDate = '2024-01-01'
                    EndDate   = '2024-01-14'
                },
                @{
                    Path      = 'Sprint 2'
                    StartDate = '2024-01-15'
                    EndDate   = '2024-02-11'
                }
            )
            Ensure = 'Present'
        }
        
        AzDoIterationNodes 'APIProjectIterations' {
            ProjectName         = 'APIServices'
            IterationAttributes = @(
                @{
                    Path      = 'Release 1.0'
                    StartDate = '2024-01-01'
                    EndDate   = '2024-03-31'
                },
                @{
                    Path      = 'Release 2.0'
                    StartDate = '2024-04-01'
                    EndDate   = '2024-06-30'
                }
            )
            Ensure = 'Present'
        }
    }
}

MultiProjectIterations
Start-DscConfiguration -Path ./MultiProjectIterations -Wait -Verbose
```

## Important Notes

### Date Formats

- Dates must be provided in 'YYYY-MM-DD' format
- Start date should be before or equal to end date
- Dates are typically business dates (Monday-Friday for sprints)

### Iteration Hierarchy

- Use backslash to separate hierarchy levels (e.g., 'Release 2024\Q1\Sprint 1')
- Parent iterations must be created before child iterations
- Hierarchy depth typically follows Release > Quarter > Sprint pattern

### Sprint Planning Best Practices

- Keep sprints to 1-3 weeks for most teams
- Align quarter boundaries to calendar quarters when possible
- Allow buffer time between iterations for planning and review

### Iteration Management

- Creating iterations does not affect existing work items
- Removing iterations may require reassigning work items first
- Completed iterations can be archived but should not be deleted

## Troubleshooting

### Issue: "Project Not Found"

**Cause**: The specified project does not exist

**Solution**:
```powershell
# Verify the project name matches exactly
# Ensure the project exists before creating iterations
```

### Issue: "Invalid Date Format"

**Cause**: Dates not in YYYY-MM-DD format

**Solution**:
```powershell
# Ensure all dates follow YYYY-MM-DD format
# Example: '2024-01-15' is correct, '1/15/2024' is not
```

### Issue: "Cannot Create Iteration Hierarchy"

**Cause**: Parent iteration does not exist

**Solution**:
- Create parent iterations before child iterations
- Verify all path components exist in the hierarchy

### Issue: "Dates Appear Incorrect in UI"

**Cause**: Timezone or daylight saving time adjustment

**Solution**:
```powershell
# Dates are stored in UTC; verify local timezone settings
# Account for daylight saving time transitions
```

## Related Resources

- [AzDoProject](AzDoProject) - Create and manage Azure DevOps projects
- [AzDoAreaNodes](AzDoAreaNodes) - Manage area nodes in projects
- [AzDoIterationPermission](AzDoIterationPermission) - Manage iteration permissions
- [AzDoWIPTags](AzDoWIPTags) - Configure work-in-progress tags

## See Also

- [Azure DevOps Documentation](https://docs.microsoft.com/en-us/azure/devops/)
- [PowerShell DSC Documentation](https://docs.microsoft.com/en-us/powershell/dsc/overview)
- [AzureDevOpsDscNative Home](../Home)
