# AzDoProjectServices Resource

## Description

The `AzDoProjectServices` DSC resource is used to manage the services enabled or disabled for an Azure DevOps project. It allows you to control which services (Git Repositories, Work Boards, Build Pipelines, Test Plans, and Azure Artifacts) are available within a project.

## Syntax

```powershell
AzDoProjectServices [string] #ResourceName
{
    ProjectName = [String] $ProjectName
    [ GitRepositories = [String] {'Enabled', 'Disabled'} ]
    [ WorkBoards = [String] {'Enabled', 'Disabled'} ]
    [ BuildPipelines = [String] {'Enabled', 'Disabled'} ]
    [ TestPlans = [String] {'Enabled', 'Disabled'} ]
    [ AzureArtifact = [String] {'Enabled', 'Disabled'} ]
    [ Ensure = [String] {'Present', 'Absent'} ]
    [ DependsOn = [String[]] ]
    [ PsDscRunAsCredential = [PSCredential] ]
}
```

## Properties

### Key Properties (Required)

- **ProjectName** [String] - The name of the Azure DevOps project. This is the unique identifier for the project.

### Optional Properties

- **GitRepositories** [String] - Enable or disable Git repositories for the project:
  - `'Enabled'` - (default) Git repositories are available
  - `'Disabled'` - Git repositories are not available

- **WorkBoards** [String] - Enable or disable work boards for the project:
  - `'Enabled'` - (default) Work boards are available
  - `'Disabled'` - Work boards are not available

- **BuildPipelines** [String] - Enable or disable build pipelines for the project:
  - `'Enabled'` - (default) Build pipelines are available
  - `'Disabled'` - Build pipelines are not available

- **TestPlans** [String] - Enable or disable test plans for the project:
  - `'Enabled'` - (default) Test plans are available
  - `'Disabled'` - Test plans are not available

- **AzureArtifact** [String] - Enable or disable Azure Artifacts for the project:
  - `'Enabled'` - (default) Azure Artifacts are available
  - `'Disabled'` - Azure Artifacts are not available

- **Ensure** [String] - Desired state of the resource:
  - `'Present'` - (default) Services configuration should exist
  - `'Absent'` - Services configuration should be removed

### Common Properties

- **DependsOn** [String[]] - Dependencies on other resources. Use this to control the order of resource execution.

- **PsDscRunAsCredential** [PSCredential] - Credentials to run this resource under.

## Return Values

The resource returns the following properties:

- **ProjectName** - The name of the project
- **GitRepositories** - Current state of Git repositories ('Enabled' or 'Disabled')
- **WorkBoards** - Current state of work boards ('Enabled' or 'Disabled')
- **BuildPipelines** - Current state of build pipelines ('Enabled' or 'Disabled')
- **TestPlans** - Current state of test plans ('Enabled' or 'Disabled')
- **AzureArtifact** - Current state of Azure Artifacts ('Enabled' or 'Disabled')
- **Ensure** - Current state ('Present' or 'Absent')

## Examples

### Example 1: Enable All Services

```powershell
Configuration EnableAllServices {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoProjectServices 'EnableAll' {
            ProjectName      = 'MyProject'
            GitRepositories  = 'Enabled'
            WorkBoards       = 'Enabled'
            BuildPipelines   = 'Enabled'
            TestPlans        = 'Enabled'
            AzureArtifact    = 'Enabled'
            Ensure           = 'Present'
        }
    }
}

EnableAllServices
Start-DscConfiguration -Path ./EnableAllServices -Wait -Verbose
```

### Example 2: Configure Development Project Services

```powershell
Configuration ConfigureDevelopmentServices {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoProjectServices 'DevProjectServices' {
            ProjectName      = 'Development'
            GitRepositories  = 'Enabled'
            WorkBoards       = 'Enabled'
            BuildPipelines   = 'Enabled'
            TestPlans        = 'Disabled'
            AzureArtifact    = 'Enabled'
            Ensure           = 'Present'
        }
    }
}

ConfigureDevelopmentServices
Start-DscConfiguration -Path ./ConfigureDevelopmentServices -Wait -Verbose
```

### Example 3: Disable Specific Services for Non-Development Project

```powershell
Configuration MinimalServices {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoProjectServices 'ReadOnlyProjectServices' {
            ProjectName      = 'Documentation'
            GitRepositories  = 'Disabled'
            WorkBoards       = 'Enabled'
            BuildPipelines   = 'Disabled'
            TestPlans        = 'Disabled'
            AzureArtifact    = 'Disabled'
            Ensure           = 'Present'
        }
    }
}

MinimalServices
Start-DscConfiguration -Path ./MinimalServices -Wait -Verbose
```

### Example 4: Query Current Project Services Configuration

```powershell
# Get the current state of project services
$properties = @{
    ProjectName = 'MyProject'
}

$result = Invoke-DscResource -Name 'AzDoProjectServices' `
    -Method Get `
    -Property $properties `
    -ModuleName 'AzureDevOpsDscNative'

$result | Select-Object ProjectName, GitRepositories, WorkBoards, BuildPipelines, TestPlans, AzureArtifact
```

### Example 5: Update Project Services Configuration

```powershell
# Update a project's services configuration
$properties = @{
    ProjectName      = 'MyProject'
    GitRepositories  = 'Enabled'
    WorkBoards       = 'Enabled'
    BuildPipelines   = 'Enabled'
    TestPlans        = 'Enabled'
    AzureArtifact    = 'Disabled'
    Ensure           = 'Present'
}

Invoke-DscResource -Name 'AzDoProjectServices' `
    -Method Set `
    -Property $properties `
    -ModuleName 'AzureDevOpsDscNative'
```

## Important Notes

### Service Availability

- Enabling or disabling a service affects visibility and access for all project members
- Some services may have dependencies or licensing requirements
- Disabling a service does not delete existing configurations (e.g., pipelines) but makes them inaccessible

### Best Practices

- Plan service configurations based on project needs and team capabilities
- Consider organization policies before disabling services
- Test service changes in non-production projects first

### Licensing Considerations

- Some services may require specific Azure DevOps licensing levels
- Azure Artifacts typically requires a paid subscription
- Verify your organization's licensing before enabling premium services

## Troubleshooting

### Issue: "Cannot modify project services"

**Cause**: Insufficient permissions or project is locked

**Solution**:
```powershell
# Verify user is in Project Collection Administrators
# Check if the project is not in a locked state
```

### Issue: "Service state not updating"

**Cause**: Service has dependencies or active resources using it

**Solution**:
- Check if any pipelines or work items depend on the service
- Ensure the personal access token has sufficient permissions
- Try updating one service at a time

### Issue: "Invalid service configuration"

**Cause**: Attempting to disable a service with active dependencies

**Solution**:
```powershell
# Disable dependent resources first before disabling the service
# Or update to keep the service enabled
```

## Related Resources

- [AzDoProject](AzDoProject.md) - Create and manage Azure DevOps projects
- [AzDoPipeline](AzDoPipeline.md) - Create build and release pipelines
- [AzDoGitRepository](AzDoGitRepository.md) - Manage Git repositories
- [AzDoVariableGroup](AzDoVariableGroup.md) - Manage variable groups

## See Also

- [Azure DevOps Documentation](https://docs.microsoft.com/en-us/azure/devops/)
- [PowerShell DSC Documentation](https://docs.microsoft.com/en-us/powershell/dsc/overview)
- [AzureDevOpsDscNative Home](../Home.md)
