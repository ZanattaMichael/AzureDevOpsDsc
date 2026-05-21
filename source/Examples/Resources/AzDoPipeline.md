# DSC AzDoPipeline Resource

## Syntax

```PowerShell
AzDoPipeline [string] #ResourceName
{
    ProjectName      = [String]$ProjectName
    PipelineName     = [String]$PipelineName
    RepositoryName   = [String]$RepositoryName
    YamlPath         = [String]$YamlPath
    [ FolderPath     = [String]$FolderPath ]
    [ DefaultBranch  = [String]$DefaultBranch ]
    [ Ensure         = [String] {'Present', 'Absent'} ]
}
```

## Properties

### Common Properties

- **ProjectName**: The name of the Azure DevOps project. This property is mandatory and serves as a key property for the resource.
- **PipelineName**: The name of the pipeline. This is a key property.
- **RepositoryName**: The name of the Git repository containing the YAML pipeline definition. This is a mandatory property.
- **YamlPath**: The path to the YAML pipeline file within the repository (e.g., `.azurepipelines/build.yml`). This is a mandatory property.
- **FolderPath**: The folder path within Azure DevOps Pipelines to organise the pipeline (e.g., `\Build`). Defaults to `\`.
- **DefaultBranch**: The default branch for the pipeline. Defaults to `main`.
- **Ensure**: Specifies whether the pipeline should exist. Valid values are `Present` and `Absent`.

## Additional Information

This resource manages YAML-based pipelines in Azure DevOps. It creates or removes pipeline definitions that reference YAML files stored in a Git repository.

## Examples

## Example 1: Sample Configuration using AzDoPipeline Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoPipeline AddPipeline {
            Ensure         = 'Present'
            ProjectName    = 'MyProject'
            PipelineName   = 'MyBuildPipeline'
            RepositoryName = 'MyRepository'
            YamlPath       = '.azurepipelines/build.yml'
            FolderPath     = '\'
            DefaultBranch  = 'main'
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoPipeline
$properties = @{
    ProjectName    = 'MyProject'
    PipelineName   = 'MyBuildPipeline'
    RepositoryName = 'MyRepository'
    YamlPath       = '.azurepipelines/build.yml'
}

Invoke-DscResource -Name 'AzDoPipeline' -Method Get -Property $properties -ModuleName 'AzureDevOpsDsc'
```

## Example 3: Sample Configuration using AzDO-DSC-LCM

``` YAML
parameters: {}

variables: {
  ProjectName: MyProject,
  RepositoryName: MyRepository
}

resources:
- name: My Build Pipeline
  type: AzureDevOpsDsc/AzDoPipeline
  dependsOn:
    - AzureDevOpsDsc/AzDoGitRepository/MyRepository
  properties:
    ProjectName: $ProjectName
    PipelineName: MyBuildPipeline
    RepositoryName: $RepositoryName
    YamlPath: .azurepipelines/build.yml
    FolderPath: '\'
    DefaultBranch: main
    Ensure: Present
```

LCM Initialization:

``` PowerShell

$params = @{
    AzureDevopsOrganizationName = "SampleAzDoOrgName"
    ConfigurationDirectory      = "C:\Datum\DSCOutput\"
    ConfigurationUrl            = 'https://configuration-path'
    JITToken                    = 'SampleJITToken'
    Mode                        = 'Set'
    AuthenticationType          = 'ManagedIdentity'
    ReportPath                  = 'C:\Datum\DSCOutput\Reports'
}

Invoke-AzDoLCM @params
```
