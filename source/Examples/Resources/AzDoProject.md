# DSC AzDoProject Resource

## Syntax

``` PowerShell
AzDoProject [string] #ResourceName
{
    ProjectName              = [String]$ProjectName
    [ Ensure                 = [String] {'Present', 'Absent'} ]
    [ ProjectDescription     = [String]$ProjectDescription ]
    [ SourceControlType      = [String] {'Git', 'Tfvc'} ]
    [ ProcessTemplate        = [String] {'Agile', 'Scrum', 'CMMI', 'Basic'} ]
    [ Visibility             = [String] {'Public', 'Private'} ]
}
```

## Properties

### Common Properties

- **ProjectName**: The name of the Azure DevOps project. This property is mandatory and serves as a key property for the resource.
- **ProjectDescription**: A description for the Azure DevOps project.
- **SourceControlType**: The type of source control (`Git` or `Tfvc`). Defaults to `Git`.
- **ProcessTemplate**: The process template to use (`Agile`, `Scrum`, `CMMI`, `Basic`). Defaults to `Agile`.
- **Visibility**: The visibility of the project (`Public` or `Private`). Defaults to `Private`.
- **Ensure**: Specifies whether the project should exist. Valid values are `Present` and `Absent`.

## Additional Information

This resource manages Azure DevOps projects using Desired State Configuration (DSC). It allows you to define project properties such as source control type, process template, and visibility, ensuring the project is configured to the desired state.

## Examples

## Example 1: Sample Configuration using AzDoProject Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoProject AddProject {
            Ensure             = 'Present'
            ProjectName        = 'MySampleProject'
            ProjectDescription = 'This is a sample Azure DevOps project.'
            SourceControlType  = 'Git'
            ProcessTemplate    = 'Agile'
            Visibility         = 'Private'
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoProject
$properties = @{
    ProjectName        = 'MySampleProject'
    ProjectDescription = 'This is a sample Azure DevOps project'
    SourceControlType  = 'Git'
    ProcessTemplate    = 'Agile'
    Visibility         = 'Private'
}

Invoke-DscResource -Name 'AzDoProject' -Method Get -Property $properties -ModuleName 'AzureDevOpsDsc'
```

## Example 3: Sample Configuration using AzDO-DSC-LCM

``` YAML
parameters: {}

variables: {
  ProjectName: MySampleProject,
  ProjectDescription: This is a sample Azure DevOps project
}

resources:
- name: My Sample Project
  type: AzureDevOpsDsc/AzDoProject
  properties:
    ProjectName: $ProjectName
    ProjectDescription: $ProjectDescription
    SourceControlType: Git
    ProcessTemplate: Agile
    Visibility: Private
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
