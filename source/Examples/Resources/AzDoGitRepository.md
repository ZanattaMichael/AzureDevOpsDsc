# DSC AzDoGitRepository Resource

## Syntax

```PowerShell
AzDoGitRepository [string] #ResourceName
{
    ProjectName                    = [String]$ProjectName
    RepositoryName                 = [String]$RepositoryName
    [ SourceRepository             = [String]$SourceRepository ]
    [ SourceType                   = [String] {'', 'Import', 'Fork'} ]
    [ ImportServiceConnectionName  = [String]$ImportServiceConnectionName ]
    [ IsDisabled                   = [Boolean]$IsDisabled ]
    [ Ensure                       = [String] {'Present', 'Absent'} ]
}
```

## Properties

### Common Properties

- **ProjectName**: The name of the Azure DevOps project that contains the repository. This property is mandatory.
- **RepositoryName**: The name of the Git repository within the project. This property is mandatory and is the key property for the resource.
- **SourceRepository**: Optional, create-time only. The source to seed the new repository from. This is only ever used when the repository is created (`New()`) - it has no effect on an existing repository, is never re-applied by `Set()`, and never causes `Test()` to report drift. Its meaning depends on `SourceType`:
  - As an **Import** source, an external Git URL (e.g. `https://github.com/octocat/Hello-World.git` or an SSH remote such as `git@host:owner/repo.git`) whose content is cloned into the new repository via the Import Requests API. The import is polled until it completes; a failed or timed-out import is surfaced as an error rather than left as a silently-empty repository.
  - As a **Fork** source, the name of an existing repository in this organization to fork from - either `RepositoryName` alone (same project as `ProjectName`), or `Project/RepositoryName` to fork from a different project.
- **SourceType**: Optional, create-time only. Picks how `SourceRepository` is interpreted - `'Import'` or `'Fork'`. When omitted, it is inferred from the shape of `SourceRepository`: a value that looks like a URL or SSH remote is treated as `'Import'`, anything else as `'Fork'`.
- **ImportServiceConnectionName**: Optional, create-time only. The name of a generic Git service connection in `ProjectName` used to authenticate an `'Import'` against a private source repository. Omit it for a public source.
- **IsDisabled**: Optional. Whether the repository is disabled. Unlike the source properties above, this can be changed at any time via `Set()`.
- **Ensure**: Specifies whether the repository should exist. Valid values are `Present` and `Absent`. Defaults to `Present`.

## Permission Usage

Not applicable for this resource.

## Permission List

Not applicable for this resource.

## Additional Information

This resource manages Git repositories in Azure DevOps projects using Desired State Configuration (DSC). It supports creating empty repositories, importing the content of an external Git repository, and forking an existing repository in the same organization. See `1-AddAzDoGitRepository.ps1` for import/fork examples.

## Examples

## Example 1: Sample Configuration using AzDoGitRepository Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    Node localhost {
        AzDoGitRepository AddGitRepository {
            Ensure           = 'Present'
            ProjectName      = 'MyProject'
            RepositoryName   = 'MyRepository'
            SourceRepository = 'TemplateRepository'
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoGitRepository
$properties = @{
    ProjectName    = 'MyProject'
    RepositoryName = 'MyRepository'
}

Invoke-DscResource -Name 'AzDoGitRepository' -Method Get -Property $properties -ModuleName 'AzureDevOpsDscNative'
```

## Example 3: Sample Configuration using Dsc.PipelineRunner

``` YAML
parameters: {}

variables: {
  ProjectName: MyProject,
  RepositoryName: MyRepository
}

resources:
- name: My Git Repository
  type: AzureDevOpsDscNative/AzDoGitRepository
  dependsOn:
    - AzureDevOpsDscNative/AzDoProject/MyProject
  properties:
    ProjectName: $ProjectName
    RepositoryName: $RepositoryName
    SourceRepository: TemplateRepository
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
