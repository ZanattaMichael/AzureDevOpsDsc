# DSC AzDoPipeline Resource

## Syntax

```PowerShell
AzDoPipeline [string] #ResourceName
{
    ProjectName             = [String]$ProjectName
    PipelineName            = [String]$PipelineName
    RepositoryName          = [String]$RepositoryName
    YamlPath                = [String]$YamlPath
    [ FolderPath            = [String]$FolderPath ]
    [ DefaultBranch         = [String]$DefaultBranch ]
    [ RepositoryType        = [String] {'TfsGit', 'GitHub', 'GitHubEnterprise', 'Bitbucket'} ]
    [ ServiceConnectionName = [String]$ServiceConnectionName ]
    [ Variables             = [Hashtable[]]$Variables ]
    [ Ensure                = [String] {'Present', 'Absent'} ]
}
```

## Properties

### Common Properties

- **ProjectName**: The name of the Azure DevOps project. This property is mandatory and serves as a key property for the resource.
- **PipelineName**: The name of the pipeline. This is a key property.
- **RepositoryName**: The repository containing the YAML pipeline definition. For `RepositoryType = 'TfsGit'` this is an Azure Repos Git repository name; for `GitHub`, `GitHubEnterprise` or `Bitbucket` it is the `owner/repo` full name. This is a mandatory property.
- **YamlPath**: The path to the YAML pipeline file within the repository (e.g., `.azurepipelines/build.yml`). This is a mandatory property.
- **FolderPath**: The folder path within Azure DevOps Pipelines to organise the pipeline (e.g., `\Build`). Defaults to `\`.
- **DefaultBranch**: The default branch for the pipeline. Defaults to `main`.
- **RepositoryType**: The type of repository backing the pipeline: `TfsGit` (Azure Repos, the default), `GitHub`, `GitHubEnterprise` or `Bitbucket`.
- **ServiceConnectionName**: The name of the service connection used to reach the repository. Required when `RepositoryType` is not `TfsGit`.
- **Variables**: Pipeline variables to manage, as an array of hashtables shaped `@{ Name; Value; IsSecret; AllowOverride }`. Only the variables listed here are managed - other variables already on the pipeline are left untouched. Secret variable values are write-only: Azure DevOps never returns a secret's value, so drift detection for a secret variable compares only its presence, `IsSecret` and `AllowOverride` flags, never its value; `Set`/`New` always write the value the configuration currently holds.
- **Ensure**: Specifies whether the pipeline should exist. Valid values are `Present` and `Absent`.

## Additional Information

This resource manages YAML-based pipelines in Azure DevOps. It creates or removes pipeline definitions that reference YAML files stored in a Git repository, GitHub, GitHub Enterprise or Bitbucket, and can manage the pipeline's variables.

> **Live test coverage**: the GitHub/GitHub Enterprise/Bitbucket `RepositoryType` values and the `ServiceConnectionName` resolution path are covered by unit tests only. The live integration organization used in CI has no GitHub or Bitbucket service connection configured, so there is no live-organization coverage of those repository types - only of `TfsGit`. See `docs/ResourceRoadmap.md`.

## Examples

## Example 1: Sample Configuration using AzDoPipeline Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

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

## Example 2: A pipeline backed by GitHub, with variables

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    Node localhost {
        AzDoPipeline AddGitHubPipeline {
            Ensure                = 'Present'
            ProjectName           = 'MyProject'
            PipelineName          = 'MyGitHubPipeline'
            RepositoryType        = 'GitHub'
            RepositoryName        = 'my-org/my-repo'
            ServiceConnectionName = 'GitHub-my-org'
            YamlPath              = '.azurepipelines/build.yml'
            Variables             = @(
                @{ Name = 'Environment'; Value = 'Production' }
                @{ Name = 'ApiKey'; Value = 's3cr3t'; IsSecret = $true; AllowOverride = $false }
            )
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 3: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoPipeline
$properties = @{
    ProjectName    = 'MyProject'
    PipelineName   = 'MyBuildPipeline'
    RepositoryName = 'MyRepository'
    YamlPath       = '.azurepipelines/build.yml'
}

Invoke-DscResource -Name 'AzDoPipeline' -Method Get -Property $properties -ModuleName 'AzureDevOpsDscNative'
```

## Example 4: Sample Configuration using Dsc.PipelineRunner

``` YAML
parameters: {}

variables: {
  ProjectName: MyProject,
  RepositoryName: MyRepository
}

resources:
- name: My Build Pipeline
  type: AzureDevOpsDscNative/AzDoPipeline
  dependsOn:
    - AzureDevOpsDscNative/AzDoGitRepository/MyRepository
  properties:
    ProjectName: $ProjectName
    PipelineName: MyBuildPipeline
    RepositoryName: $RepositoryName
    YamlPath: .azurepipelines/build.yml
    FolderPath: '\'
    DefaultBranch: main
    Ensure: Present
```

Pipeline runner initialization:

``` PowerShell

Import-Module Dsc.PipelineRunner

$params = @{
    AzureDevopsOrganizationName = "SampleAzDoOrgName"
    exportConfigDir             = "C:\Datum\DSCOutput\"
    ConfigurationSourcePath     = 'https://configuration-path'
    JITToken                    = 'SampleJITToken'
    Mode                        = 'Set'
    AuthenticationType          = 'ManagedIdentity'
    ReportPath                  = 'C:\Datum\DSCOutput\Reports'
}

Invoke-DscPipelineRunner @params
```
