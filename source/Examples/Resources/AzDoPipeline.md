# DSC AzDoPipeline Resource

# Syntax

``` PowerShell
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

# Common Properties

- __ProjectName__: The name of the Azure DevOps project. This is a key property.
- __PipelineName__: The name of the pipeline. This is a key property.
- __RepositoryName__: The name of the Git repository containing the YAML pipeline definition. This is a mandatory property.
- __YamlPath__: The path to the YAML pipeline file within the repository (e.g., `.azurepipelines/build.yml`). This is a mandatory property.
- __FolderPath__: The folder path within Azure DevOps Pipelines to organize the pipeline (e.g., `\Build`). Defaults to `\`.
- __DefaultBranch__: The default branch for the pipeline. Defaults to `main`.
- __Ensure__: Specifies whether the pipeline should exist. Valid values are `Present` and `Absent`. Defaults to `Present`.

# Additional Information

This resource manages YAML-based pipelines in Azure DevOps. It creates or removes pipeline definitions that reference YAML files stored in a Git repository.

# Examples

## Example 1: Create a pipeline

``` PowerShell
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoPipeline 'AddPipeline' {
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
```

## Example 2: Remove a pipeline

``` PowerShell
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoPipeline 'RemovePipeline' {
            Ensure         = 'Absent'
            ProjectName    = 'MyProject'
            PipelineName   = 'MyBuildPipeline'
            RepositoryName = 'MyRepository'
            YamlPath       = '.azurepipelines/build.yml'
        }
    }
}
```
