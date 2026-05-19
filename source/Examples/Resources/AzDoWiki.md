# DSC AzDoWiki Resource

## Syntax

```PowerShell
AzDoWiki [string] #ResourceName
{
    ProjectName        = [String]$ProjectName
    WikiName           = [String]$WikiName
    [ WikiType         = [String] {'projectWiki', 'codeWiki'} ]
    [ RepositoryName   = [String]$RepositoryName ]
    [ MappedPath       = [String]$MappedPath ]
    [ Version          = [String]$Version ]
    [ Ensure           = [String] {'Present', 'Absent'} ]
}
```

## Properties

### Common Properties

- **ProjectName**: The name of the Azure DevOps project. This property is mandatory and serves as a key property for the resource.
- **WikiName**: The name of the wiki. This is a key property.
- **WikiType**: The type of wiki. Valid values are `projectWiki` (a built-in project wiki) and `codeWiki` (a wiki sourced from a Git repository). Defaults to `projectWiki`.
- **RepositoryName**: For `codeWiki` type, the name of the repository that contains the wiki content. Optional.
- **MappedPath**: For `codeWiki` type, the folder path within the repository that contains the wiki content. Defaults to `/`.
- **Version**: For `codeWiki` type, the branch or commit to use. Optional.
- **Ensure**: Specifies whether the wiki should exist. Valid values are `Present` and `Absent`.

## Additional Information

This resource manages wikis in Azure DevOps projects. Project wikis are automatically created within the project, while code wikis are sourced from content stored in a Git repository.

## Examples

## Example 1: Sample Configuration using AzDoWiki Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoWiki AddProjectWiki {
            Ensure      = 'Present'
            ProjectName = 'MyProject'
            WikiName    = 'MyProjectWiki'
            WikiType    = 'projectWiki'
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoWiki
$properties = @{
    ProjectName = 'MyProject'
    WikiName    = 'MyProjectWiki'
}

Invoke-DscResource -Name 'AzDoWiki' -Method Get -Property $properties -ModuleName 'AzureDevOpsDsc'
```

## Example 3: Sample Configuration using AzDO-DSC-LCM

``` YAML
parameters: {}

variables: {
  ProjectName: MyProject,
  RepositoryName: MyRepository
}

resources:
- name: Project Wiki
  type: AzureDevOpsDsc/AzDoWiki
  dependsOn:
    - AzureDevOpsDsc/AzDevOpsProject/MyProject
  properties:
    ProjectName: $ProjectName
    WikiName: MyProjectWiki
    WikiType: projectWiki
    Ensure: Present

- name: Code Wiki
  type: AzureDevOpsDsc/AzDoWiki
  dependsOn:
    - AzureDevOpsDsc/AzDoGitRepository/MyRepository
  properties:
    ProjectName: $ProjectName
    WikiName: MyCodeWiki
    WikiType: codeWiki
    RepositoryName: $RepositoryName
    MappedPath: /docs
    Version: main
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
