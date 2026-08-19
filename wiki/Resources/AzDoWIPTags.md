# AzDoWIPTags Resource

## Description

The `AzDoWIPTags` DSC resource is used to configure work-in-progress (WIP) tags for work items in an Azure DevOps project. WIP tags help identify and track work items that should not be moved to done or completed status, providing visual indicators for items under active development or in special states.

## Syntax

```powershell
AzDoWIPTags [string] #ResourceName
{
    ProjectName = [String] $ProjectName
    WorkItemTrackingTagList = [String[]] $WorkItemTrackingTagList
    [ Ensure = [String] {'Present', 'Absent'} ]
    [ DependsOn = [String[]] ]
    [ PsDscRunAsCredential = [PSCredential] ]
}
```

## Properties

### Key Properties (Required)

- **ProjectName** [String] - The name of the Azure DevOps project.

- **WorkItemTrackingTagList** [String[]] - An array of tag names to configure as WIP tags (e.g., @('OnHold', 'InReview', 'Blocked')).

### Optional Properties

- **Ensure** [String] - Desired state of the resource:
  - `'Present'` - (default) WIP tags should be configured
  - `'Absent'` - WIP tags should be removed

### Common Properties

- **DependsOn** [String[]] - Dependencies on other resources. Use this to control the order of resource execution.

- **PsDscRunAsCredential** [PSCredential] - Credentials to run this resource under.

## Return Values

The resource returns the following properties:

- **ProjectName** - The name of the project
- **WorkItemTrackingTagList** - The list of configured WIP tags
- **Ensure** - Current state ('Present' or 'Absent')

## Examples

### Example 1: Configure Basic WIP Tags

```powershell
Configuration ConfigureWIPTags {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoWIPTags 'StandardWIPTags' {
            ProjectName               = 'MyProject'
            WorkItemTrackingTagList   = @('OnHold', 'Blocked', 'InReview')
            Ensure                    = 'Present'
        }
    }
}

ConfigureWIPTags
Start-DscConfiguration -Path ./ConfigureWIPTags -Wait -Verbose
```

### Example 2: Configure Comprehensive WIP Tags

```powershell
Configuration ComprehensiveWIPTags {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoWIPTags 'DetailedWIPTags' {
            ProjectName               = 'MyProject'
            WorkItemTrackingTagList   = @(
                'OnHold',
                'Blocked-External',
                'Blocked-Internal',
                'InReview',
                'WaitingForFeedback',
                'Technical-Debt',
                'Performance-Investigation'
            )
            Ensure                    = 'Present'
        }
    }
}

ComprehensiveWIPTags
Start-DscConfiguration -Path ./ComprehensiveWIPTags -Wait -Verbose
```

### Example 3: Configure WIP Tags for Multiple Projects

```powershell
Configuration MultiProjectWIPTags {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoWIPTags 'WebProjectWIPTags' {
            ProjectName               = 'WebApplication'
            WorkItemTrackingTagList   = @('OnHold', 'Blocked', 'InReview')
            Ensure                    = 'Present'
        }
        
        AzDoWIPTags 'APIProjectWIPTags' {
            ProjectName               = 'APIServices'
            WorkItemTrackingTagList   = @('OnHold', 'Blocked', 'Architecture-Review')
            Ensure                    = 'Present'
        }
        
        AzDoWIPTags 'MobileProjectWIPTags' {
            ProjectName               = 'MobileApp'
            WorkItemTrackingTagList   = @('OnHold', 'Blocked', 'Testing')
            Ensure                    = 'Present'
        }
    }
}

MultiProjectWIPTags
Start-DscConfiguration -Path ./MultiProjectWIPTags -Wait -Verbose
```

### Example 4: Query Current WIP Tags Configuration

```powershell
# Get the current state of WIP tags
$properties = @{
    ProjectName = 'MyProject'
}

$result = Invoke-DscResource -Name 'AzDoWIPTags' `
    -Method Get `
    -Property $properties `
    -ModuleName 'AzureDevOpsDscNative'

$result | Select-Object ProjectName, WorkItemTrackingTagList, Ensure
```

### Example 5: Update WIP Tags Configuration

```powershell
Configuration UpdateWIPTags {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoWIPTags 'UpdatedWIPTags' {
            ProjectName               = 'MyProject'
            WorkItemTrackingTagList   = @(
                'OnHold',
                'Blocked',
                'InReview',
                'SecurityReview',
                'ComplianceReview'
            )
            Ensure                    = 'Present'
        }
    }
}

UpdateWIPTags
Start-DscConfiguration -Path ./UpdateWIPTags -Wait -Verbose
```

### Example 6: Environment-Specific WIP Tags

```powershell
Configuration EnvironmentSpecificWIPTags {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoWIPTags 'DevelopmentWIP' {
            ProjectName               = 'Dev-Project'
            WorkItemTrackingTagList   = @('OnHold', 'Blocked', 'InReview', 'LocalTesting')
            Ensure                    = 'Present'
        }
        
        AzDoWIPTags 'ProductionWIP' {
            ProjectName               = 'Prod-Project'
            WorkItemTrackingTagList   = @('OnHold', 'Blocked', 'Critical-Review', 'ReleaseCandidate')
            Ensure                    = 'Present'
        }
    }
}

EnvironmentSpecificWIPTags
Start-DscConfiguration -Path ./EnvironmentSpecificWIPTags -Wait -Verbose
```

## Important Notes

### Tag Purpose

- WIP tags serve as visual indicators for work items in special states
- They help teams identify items that should not proceed without additional action
- Tags improve visibility and communication within teams

### Best Practices

- Keep tag names clear and descriptive
- Establish team conventions for tag usage
- Periodically review and update tags based on team needs
- Document tag meanings and when they should be applied

### Tag Management

- Tags should be configured at project creation time if possible
- Updating tags will affect existing work items with those tags
- Consider impact on existing work items before removing tags

## Troubleshooting

### Issue: "Project Not Found"

**Cause**: The specified project does not exist

**Solution**:
```powershell
# Verify the project name matches exactly
# Ensure the project exists before attempting to configure WIP tags
# Use AzDoProject resource to create the project first
```

### Issue: "Cannot Configure WIP Tags"

**Cause**: Insufficient permissions or tag conflicts

**Solution**:
- Verify user has project administrator permissions
- Check personal access token has appropriate scope
- Ensure tag names don't conflict with existing system tags

### Issue: "Tags Not Visible in Work Items"

**Cause**: Tags may not be displayed in current work item views

**Solution**:
```powershell
# Configure work item form to display tags field
# Verify team settings show tags on work items
# Check work item process customization
```

## Related Resources

- [AzDoProject](AzDoProject.md) - Create and manage Azure DevOps projects
- [AzDoAreaNodes](AzDoAreaNodes.md) - Manage area nodes in a project
- [AzDoIterationNodes](AzDoIterationNodes.md) - Manage iteration nodes in a project

## See Also

- [Azure DevOps Documentation](https://docs.microsoft.com/en-us/azure/devops/)
- [PowerShell DSC Documentation](https://docs.microsoft.com/en-us/powershell/dsc/overview)
- [AzureDevOpsDscNative Home](../Home.md)
