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

- **ProjectName**: The name of the Azure DevOps project. This property is mandatory and serves as a key property for the resource.
- **RepositoryName**: The name of the Git repository within the project. This is a key property.
- **SourceRepository**: (Optional) The name of a source repository from which to initialize the new repository.
- **Ensure**: Specifies whether the repository should exist. Valid values are `Present` and `Absent`.

## Additional Information

This resource manages Git repositories in Azure DevOps projects using Desired State Configuration (DSC). It supports creating repositories from scratch or initializing them from a source/template repository.

## Examples

## Example 1: Sample Configuration using AzDoGitRepository Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

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

Invoke-DscResource -Name 'AzDoGitRepository' -Method Get -Property $properties -ModuleName 'AzureDevOpsDsc'
```

## Example 3: Sample Configuration using AzDO-DSC-LCM

``` YAML
parameters: {}

variables: {
  ProjectName: MyProject,
  RepositoryName: MyRepository
}

resources:
- name: My Git Repository
  type: AzureDevOpsDsc/AzDoGitRepository
  dependsOn:
    - AzureDevOpsDsc/AzDoProject/MyProject
  properties:
    ProjectName: $ProjectName
    RepositoryName: $RepositoryName
    SourceRepository: TemplateRepository
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
