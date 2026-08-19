# AzDoPipeline Resource

## Description

The `AzDoPipeline` DSC resource is used to create and manage YAML-based pipelines in Azure DevOps. YAML pipelines are defined using YAML files stored in Git repositories and provide infrastructure-as-code for continuous integration and continuous deployment. This resource allows you to define and enforce the desired state of pipeline definitions, specifying which repository, YAML file, and branch should be used.

## Syntax

```powershell
AzDoPipeline [string] #ResourceName
{
    ProjectName = [String] $ProjectName
    PipelineName = [String] $PipelineName
    RepositoryName = [String] $RepositoryName
    YamlPath = [String] $YamlPath
    [ FolderPath = [String] $FolderPath ]
    [ DefaultBranch = [String] $DefaultBranch ]
    [ Ensure = [String] {'Present', 'Absent'} ]
    [ DependsOn = [String[]] ]
    [ PsDscRunAsCredential = [PSCredential] ]
}
```

## Properties

### Key Properties (Required)

- **ProjectName** [String] - The name of the Azure DevOps project where the pipeline will be created.

### Mandatory Properties

- **PipelineName** [String] - The name/display name of the pipeline. This is the human-readable identifier used in the UI and when queuing builds.

- **RepositoryName** [String] - The name of the Git repository containing the YAML pipeline definition. The repository must exist in the project.

- **YamlPath** [String] - The path to the YAML file within the repository that defines the pipeline (e.g., `azure-pipelines.yml`, `build/ci.yaml`, `pipelines/build.yml`).

### Optional Properties

- **FolderPath** [String] - The folder path where the pipeline is organized within the project. Pipelines can be organized in a hierarchical folder structure. Default is `\` (root folder).

- **DefaultBranch** [String] - The default branch from which to run the pipeline (e.g., 'main', 'master', 'develop'). This branch is used when manually queuing builds. Default is `'main'`.

- **Ensure** [String] - Desired state of the resource:
  - `'Present'` - (default) Pipeline should exist
  - `'Absent'` - Pipeline should be removed

### Common Properties

- **DependsOn** [String[]] - Dependencies on other resources. Use this to control the order of resource execution.

- **PsDscRunAsCredential** [PSCredential] - Credentials to run this resource under.

## Return Values

The resource returns the following properties:

- **ProjectName** - The name of the project
- **PipelineName** - The name of the pipeline
- **RepositoryName** - The name of the repository
- **YamlPath** - The path to the YAML file
- **FolderPath** - The folder organization path
- **DefaultBranch** - The default branch for the pipeline
- **Ensure** - Current state ('Present' or 'Absent')

## Examples

### Example 1: Create a Basic CI Pipeline

```powershell
Configuration CreateCIPipeline {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        AzDoPipeline 'ContinuousIntegration' {
            ProjectName = 'MyProject'
            PipelineName = 'CI - Main'
            RepositoryName = 'MainRepository'
            YamlPath = 'azure-pipelines.yml'
            FolderPath = '\'
            DefaultBranch = 'main'
            Ensure = 'Present'
        }
    }
}

CreateCIPipeline
Start-DscConfiguration -Path ./CreateCIPipeline -Wait -Verbose
```

### Example 2: Create Multiple Pipelines with Organized Folder Structure

```powershell
Configuration CreateMultiplePipelines {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        # Build pipeline
        AzDoPipeline 'BuildPipeline' {
            ProjectName = 'MyProject'
            PipelineName = 'Build'
            RepositoryName = 'MainRepository'
            YamlPath = 'pipelines/build.yml'
            FolderPath = '\Build'
            DefaultBranch = 'main'
            Ensure = 'Present'
        }
        
        # Test pipeline
        AzDoPipeline 'TestPipeline' {
            ProjectName = 'MyProject'
            PipelineName = 'Run Tests'
            RepositoryName = 'MainRepository'
            YamlPath = 'pipelines/test.yml'
            FolderPath = '\Testing'
            DefaultBranch = 'main'
            Ensure = 'Present'
            DependsOn = '[AzDoPipeline]BuildPipeline'
        }
        
        # Release pipeline
        AzDoPipeline 'ReleasePipeline' {
            ProjectName = 'MyProject'
            PipelineName = 'Release to Production'
            RepositoryName = 'MainRepository'
            YamlPath = 'pipelines/release.yml'
            FolderPath = '\Release'
            DefaultBranch = 'main'
            Ensure = 'Present'
            DependsOn = '[AzDoPipeline]TestPipeline'
        }
    }
}

CreateMultiplePipelines
Start-DscConfiguration -Path ./CreateMultiplePipelines -Wait -Verbose
```

### Example 3: Create Pipelines for Multiple Repositories

```powershell
Configuration CreatePipelinesMultipleRepos {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        # Frontend repo pipeline
        AzDoPipeline 'FrontendPipeline' {
            ProjectName = 'MyProject'
            PipelineName = 'Frontend CI/CD'
            RepositoryName = 'Frontend'
            YamlPath = 'azure-pipelines.yml'
            FolderPath = '\Applications\Frontend'
            DefaultBranch = 'develop'
            Ensure = 'Present'
        }
        
        # Backend repo pipeline
        AzDoPipeline 'BackendPipeline' {
            ProjectName = 'MyProject'
            PipelineName = 'Backend CI/CD'
            RepositoryName = 'Backend'
            YamlPath = 'azure-pipelines.yml'
            FolderPath = '\Applications\Backend'
            DefaultBranch = 'develop'
            Ensure = 'Present'
        }
        
        # Infrastructure repo pipeline
        AzDoPipeline 'InfraPipeline' {
            ProjectName = 'MyProject'
            PipelineName = 'Infrastructure Deployment'
            RepositoryName = 'Infrastructure'
            YamlPath = 'pipelines/deploy.yml'
            FolderPath = '\Infrastructure'
            DefaultBranch = 'main'
            Ensure = 'Present'
        }
    }
}

CreatePipelinesMultipleRepos
Start-DscConfiguration -Path ./CreatePipelinesMultipleRepos -Wait -Verbose
```

### Example 4: Create Pipelines for Pull Request Validation

```powershell
Configuration CreatePRValidationPipelines {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'
    
    Node localhost {
        # PR validation for main branch
        AzDoPipeline 'PRValidation' {
            ProjectName = 'MyProject'
            PipelineName = 'PR Validation'
            RepositoryName = 'MainRepository'
            YamlPath = 'pipelines/pr-validation.yml'
            FolderPath = '\Quality Assurance'
            DefaultBranch = 'main'
            Ensure = 'Present'
        }
        
        # PR validation for develop branch
        AzDoPipeline 'PRValidationDevelop' {
            ProjectName = 'MyProject'
            PipelineName = 'PR Validation - Develop'
            RepositoryName = 'MainRepository'
            YamlPath = 'pipelines/pr-validation-dev.yml'
            FolderPath = '\Quality Assurance'
            DefaultBranch = 'develop'
            Ensure = 'Present'
        }
    }
}

CreatePRValidationPipelines
Start-DscConfiguration -Path ./CreatePRValidationPipelines -Wait -Verbose
```

### Example 5: Using Invoke-DscResource to Query and Create Pipelines

```powershell
# Get current pipeline state
$properties = @{
    ProjectName = 'MyProject'
    PipelineName = 'CI - Main'
    RepositoryName = 'MainRepository'
    YamlPath = 'azure-pipelines.yml'
}

$result = Invoke-DscResource -Name 'AzDoPipeline' `
    -Method Get `
    -Property $properties `
    -ModuleName 'AzureDevOpsDscNative'

$result | Select-Object ProjectName, PipelineName, RepositoryName, YamlPath, DefaultBranch

# Create a new pipeline
$setProperties = @{
    ProjectName = 'MyProject'
    PipelineName = 'New Pipeline'
    RepositoryName = 'MainRepository'
    YamlPath = 'new-pipeline.yml'
    FolderPath = '\Pipelines'
    DefaultBranch = 'main'
    Ensure = 'Present'
}

Invoke-DscResource -Name 'AzDoPipeline' `
    -Method Set `
    -Property $setProperties `
    -ModuleName 'AzureDevOpsDscNative'
```

## Important Notes

### YAML File Structure

- The YAML file must be a valid Azure Pipelines YAML file
- Paths are relative to the repository root
- File extensions can be .yml or .yaml
- The file must exist in the specified repository and branch

### Folder Organization

- Pipelines can be organized in folders for better project structure
- Folder paths use backslash separators (e.g., `\CI\Build`, `\Release\Production`)
- Using `\` puts the pipeline in the root folder
- Folders don't need to be pre-created; they're created automatically

### Default Branch

- The default branch is used when manually queuing builds through the UI
- Branch policies and CI triggers are defined in the YAML file itself
- Different YAML files on different branches can enable different pipeline behaviors
- Using `'main'` is recommended for most projects

### Repository Requirements

- The repository must exist in the project before the pipeline can be created
- The repository must be a Git repository
- TFVC repositories are not supported for YAML pipelines

### Pipeline Naming

- Pipeline names should be descriptive and unique within the project
- Names can include spaces and special characters
- The name is distinct from the YAML file or folder structure
- Rename the pipeline through the resource update to change the display name

## Troubleshooting

### Issue: "Repository Not Found"

**Cause**: The specified repository does not exist in the project.

**Solution**:
```powershell
# Verify the repository exists using AzDoGitRepository resource
# Create the repository first if it doesn't exist
# Ensure the exact repository name is used (case-sensitive)
```

### Issue: "YAML File Not Found"

**Cause**: The YAML file does not exist at the specified path.

**Solution**:
```powershell
# Verify the YAML file exists in the repository
# Check the exact path spelling and extension
# Ensure the file exists in the specified default branch
# Use the correct format: 'path/to/pipeline.yml'
```

### Issue: "Invalid YAML Syntax"

**Cause**: The YAML file contains syntax errors.

**Solution**:
```powershell
# Validate the YAML file syntax
# Use online YAML validators if needed
# Check the pipeline configuration page for error messages
# See Azure Pipelines YAML reference documentation
```

### Issue: "Pipeline Creation Fails"

**Cause**: Various authentication or permission issues.

**Solution**:
```powershell
# Verify authentication credentials are valid
# Check project administrator permissions
# Ensure service account has repository access
# Review Azure DevOps error messages for specific issues
```

## Related Resources

- [AzDoGitRepository](AzDoGitRepository.md) - Create Git repositories for pipeline YAML files
- [AzDoPipelineSettings](AzDoPipelineSettings.md) - Configure project-level pipeline settings
- [AzDoPipelineEnvironment](AzDoPipelineEnvironment.md) - Create deployment environments for pipelines
- [AzDoProject](AzDoProject.md) - Create projects that host pipelines

## See Also

- [Azure Pipelines YAML Reference](https://docs.microsoft.com/en-us/azure/devops/pipelines/yaml-schema)
- [Azure Pipelines Documentation](https://docs.microsoft.com/en-us/azure/devops/pipelines)
- [Azure Pipelines Triggers and Events](https://docs.microsoft.com/en-us/azure/devops/pipelines/build/triggers)
- [PowerShell DSC Documentation](https://docs.microsoft.com/en-us/powershell/dsc/overview)
- [AzureDevOpsDscNative Home](../Home.md)
