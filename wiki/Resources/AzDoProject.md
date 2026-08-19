# AzDoProject Resource

## Description

The `AzDoProject` DSC resource is used to create, configure, and manage Azure DevOps projects. It allows you to define and enforce the desired state of a project, including its visibility, process template, and source control type.

## Syntax

```powershell
AzDoProject [string] #ResourceName
{
    ProjectName = [String] $ProjectName
    [ Ensure = [String] {'Present', 'Absent'} ]
    [ ProjectDescription = [String] $ProjectDescription ]
    [ SourceControlType = [String] {'Git', 'Tfvc'} ]
    [ ProcessTemplate = [String] {'Agile', 'Scrum', 'CMMI', 'Basic'} ]
    [ Visibility = [String] {'Public', 'Private'} ]
    [ DependsOn = [String[]] ]
    [ PsDscRunAsCredential = [PSCredential] ]
}
```

## Properties

### Key Properties (Required)

- **ProjectName** [String] - The name of the Azure DevOps project. This is the unique identifier for the project.

### Optional Properties

- **Ensure** [String] - Desired state of the resource:
  - `'Present'` - (default) Project should exist
  - `'Absent'` - Project should be removed

- **ProjectDescription** [String] - A description for the Azure DevOps project. Provides context about the project's purpose.

- **SourceControlType** [String] - The type of source control for the project:
  - `'Git'` - (default) Use Git version control
  - `'Tfvc'` - Use Team Foundation Version Control
  - **Note:** This cannot be changed after project creation

- **ProcessTemplate** [String] - The process template to use for the project:
  - `'Agile'` - (default) Agile process template
  - `'Scrum'` - Scrum process template
  - `'CMMI'` - CMMI process template
  - `'Basic'` - Basic process template
  - **Note:** This cannot be changed after project creation

- **Visibility** [String] - The visibility of the project:
  - `'Private'` - (default) Only authorized users can access
  - `'Public'` - Anyone in the organization can access
  - **Note:** Public projects may have limitations depending on Azure DevOps settings

### Common Properties

- **DependsOn** [String[]] - Dependencies on other resources. Use this to control the order of resource execution.

- **PsDscRunAsCredential** [PSCredential] - Credentials to run this resource under.

## Return Values

The resource returns the following properties:

- **ProjectName** - The name of the project
- **Ensure** - Current state ('Present' or 'Absent')
- **ProjectDescription** - The description of the project
- **SourceControlType** - The version control type ('Git' or 'Tfvc')
- **ProcessTemplate** - The process template ('Agile', 'Scrum', 'CMMI', or 'Basic')
- **Visibility** - The project visibility ('Public' or 'Private')
- **ProjectId** - The unique identifier of the project

## Examples

### Example 1: Create a Basic Agile Project

```powershell
Configuration CreateBasicProject {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoProject 'MyAgileProject' {
            Ensure              = 'Present'
            ProjectName         = 'MyAgileProject'
            ProjectDescription  = 'A basic Agile project'
            SourceControlType   = 'Git'
            ProcessTemplate     = 'Agile'
            Visibility          = 'Private'
        }
    }
}

CreateBasicProject
Start-DscConfiguration -Path ./CreateBasicProject -Wait -Verbose
```

### Example 2: Create a Scrum Project

```powershell
Configuration CreateScrumProject {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoProject 'MyScrumProject' {
            Ensure              = 'Present'
            ProjectName         = 'MyScrumProject'
            ProjectDescription  = 'A Scrum-based project for sprint management'
            SourceControlType   = 'Git'
            ProcessTemplate     = 'Scrum'
            Visibility          = 'Private'
        }
    }
}

CreateScrumProject
Start-DscConfiguration -Path ./CreateScrumProject -Wait -Verbose
```

### Example 3: Create Multiple Projects

```powershell
Configuration CreateMultipleProjects {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoProject 'FrontendProject' {
            Ensure              = 'Present'
            ProjectName         = 'Frontend'
            ProjectDescription  = 'Frontend application development'
            SourceControlType   = 'Git'
            ProcessTemplate     = 'Agile'
            Visibility          = 'Private'
        }
        
        AzDoProject 'BackendProject' {
            Ensure              = 'Present'
            ProjectName         = 'Backend'
            ProjectDescription  = 'Backend services and APIs'
            SourceControlType   = 'Git'
            ProcessTemplate     = 'Agile'
            Visibility          = 'Private'
        }
        
        AzDoProject 'InfrastructureProject' {
            Ensure              = 'Present'
            ProjectName         = 'Infrastructure'
            ProjectDescription  = 'Infrastructure and DevOps'
            SourceControlType   = 'Git'
            ProcessTemplate     = 'Agile'
            Visibility          = 'Private'
        }
    }
}

CreateMultipleProjects
Start-DscConfiguration -Path ./CreateMultipleProjects -Wait -Verbose
```

### Example 4: Using Get Method with Invoke-DscResource

```powershell
# Get the current state of a project
$properties = @{
    ProjectName = 'MyProject'
}

$result = Invoke-DscResource -Name 'AzDoProject' `
    -Method Get `
    -Property $properties `
    -ModuleName 'AzureDevOpsDscNative'

$result | Select-Object ProjectName, Ensure, ProjectDescription, ProcessTemplate
```

### Example 5: Using Set Method to Update Project

```powershell
# Update a project's description
$properties = @{
    ProjectName = 'MyProject'
    Ensure = 'Present'
    ProjectDescription = 'Updated project description'
    SourceControlType = 'Git'
    ProcessTemplate = 'Agile'
    Visibility = 'Private'
}

Invoke-DscResource -Name 'AzDoProject' `
    -Method Set `
    -Property $properties `
    -ModuleName 'AzureDevOpsDscNative'
```

### Example 6: Remove a Project

```powershell
Configuration RemoveProject {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoProject 'RemoveOldProject' {
            Ensure      = 'Absent'
            ProjectName = 'OldProject'
        }
    }
}

RemoveProject
Start-DscConfiguration -Path ./RemoveProject -Wait -Verbose
```

### Example 7: Configuration Data File Approach

```powershell
# ProjectsConfig.psd1
@{
    AllNodes = @(
        @{
            NodeName = 'localhost'
            Projects = @(
                @{
                    Name = 'WebApp'
                    Description = 'Web Application Project'
                    ProcessTemplate = 'Agile'
                }
                @{
                    Name = 'MobileApp'
                    Description = 'Mobile Application Project'
                    ProcessTemplate = 'Scrum'
                }
            )
        }
    )
}

# Configuration.ps1
Configuration CreateProjectsFromData {
    param([hashtable]$ConfigurationData)
    
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node $AllNodes.NodeName {
        foreach ($project in $Node.Projects) {
            AzDoProject "Project_$($project.Name)" {
                Ensure              = 'Present'
                ProjectName         = $project.Name
                ProjectDescription  = $project.Description
                SourceControlType   = 'Git'
                ProcessTemplate     = $project.ProcessTemplate
                Visibility          = 'Private'
            }
        }
    }
}

$data = Import-PowerShellDataFile -Path ProjectsConfig.psd1
CreateProjectsFromData -ConfigurationData $data
```

## Important Notes

### Immutable Properties

The following properties cannot be changed after the project is created:
- **SourceControlType** - Must be specified at creation
- **ProcessTemplate** - Must be specified at creation

If you need to change these, you must delete and recreate the project.

### Project Naming

- Project names must be unique within the organization
- Project names cannot contain certain special characters
- Project names are case-insensitive for identification but case-sensitive for display

### Organization Scope

- This resource operates at the organization level
- Ensure your authentication has appropriate permissions
- Personal Access Token should have "Project & Team" scope

### Visibility Considerations

- **Private Projects**: Only explicit members can access
- **Public Projects**: All organization members can access, but may require Azure DevOps License
- Check organization policies before setting visibility to 'Public'

## Troubleshooting

### Issue: "Project Already Exists"

**Cause**: A project with the same name already exists

**Solution**: 
```powershell
# Check existing projects
Get-DscResource -Module AzureDevOpsDscNative -Name AzDoProject
# Use a unique project name or remove the existing project first
```

### Issue: "Cannot Create Project Due to Permissions"

**Cause**: Authentication account lacks necessary permissions

**Solution**:
- Verify user is in Project Collection Administrators group
- Check Personal Access Token has "Project & Team" scope
- Ensure user has create project permissions

### Issue: "Invalid Process Template"

**Cause**: Specified process template doesn't exist or isn't available

**Solution**:
```powershell
# Use one of the standard templates
ProcessTemplate = 'Agile'  # or 'Scrum', 'CMMI', 'Basic'
# Check with your organization admin for custom templates
```

## Related Resources

- [AzDoProjectGroup](AzDoProjectGroup.md) - Manage project-level groups
- [AzDoProjectServices](AzDoProjectServices.md) - Manage services for a project
- [AzDoTeam](../Resources/AzDoTeam.md) - Create teams in a project
- [AzDoGitRepository](AzDoGitRepository.md) - Manage repositories in a project

## See Also

- [Azure DevOps Documentation](https://docs.microsoft.com/en-us/azure/devops/)
- [PowerShell DSC Documentation](https://docs.microsoft.com/en-us/powershell/dsc/overview)
- [AzureDevOpsDscNative Home](../Home.md)
