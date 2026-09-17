# DSC AzDoGitRepository Resource

## Syntax

```PowerShell
AzDoGitRepository [string] #ResourceName
{
    ProjectName          = [String]$ProjectName
    RepositoryName       = [String]$RepositoryName
    [ SourceRepository   = [String]$SourceRepository ]
    [ Ensure             = [String] {'Present', 'Absent'} ]
}
```

## Properties

### Common Properties

- **ProjectName**: The name of the Azure DevOps project that contains the repository. This property is mandatory.
- **RepositoryName**: The name of the Git repository within the project. This property is mandatory and is the key property for the resource.
- **SourceRepository**: Optional. The name of an existing repository to seed the new repository from. When omitted, an empty repository is created.
- **Ensure**: Specifies whether the repository should exist. Valid values are `Present` and `Absent`. Defaults to `Present`.

## Permission Usage

Not applicable for this resource.

## Permission List

Not applicable for this resource.

## Additional Information

This resource manages Git repositories in Azure DevOps projects using Desired State Configuration (DSC). It supports creating repositories from scratch or initializing them from a source/template repository.

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
