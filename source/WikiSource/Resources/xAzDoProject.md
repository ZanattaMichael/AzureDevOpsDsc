# DSC AzDoProject Resource

# Syntax

``` PowerShell
AzDoProject [string] #ResourceName
{
    ProjectName = [String]$ProjectName
    [ Ensure = [String] {'Present', 'Absent'}]
    [ ProjectDescription = [String]$ProjectDescription]
    [ SourceControlType = [String] {'Git', 'Tfvc'}]
    [ ProcessTemplate = [String] {'Agile', 'Scrum', 'CMMI', 'Basic'}]
    [ Visibility = [String] {'Public', 'Private'}]
}
```

# Properties

Common Properties:

- __ProjectName__: The name of the Azure DevOps project.
- __ProjectDescription__: A description for the Azure DevOps project.
- __SourceControlType__: The type of source control (Git or Tfvc). Default is Git.
- __ProcessTemplate__: The process template to use (Agile, Scrum, CMMI, Basic). Default is Agile.
- __Visibility__: The visibility of the project (Public or Private). Default is Private.

# Additional Information

This resource is used to manage Azure DevOps projects using Desired State Configuration (DSC).
It allows you to define the properties of an Azure DevOps project and ensures that the project is configured according to those properties.

# Examples

## Example 1: Sample Configuration for Azure DevOps Project using AzDoProject Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzDevOpsDsc'

    Node localhost {
        AzDoProject ProjectExample {
            Ensure             = 'Present'
            ProjectName        = 'MySampleProject'
            ProjectDescription = 'This is a sample Azure DevOps project.'
            SourceControlType  = 'Git'
            ProcessTemplate    = 'Agile'
            Visibility         = 'Private'
        }
    }
}

ExampleConfig
Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose

```

## Example 2: Sample Configuration for Azure DevOps Project using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoProject
# Ensure is not required
$properties = @{
    ProjectName             = 'MySameProject'
    ProjectDiscription      = 'This is a sample Azure DevOps project'
    SourceControlType       = 'Git'
    ProcessTemplate         = 'Agile'
    Visibility              = 'Private'
}

Invoke-DSCResource -Name 'AzDoProject' -Method Get -Property $properties -ModuleName 'AzureDevOpsDsc'
```

## Example 3: Sample Configuration to remove/exclude an Azure DevOps Project using Invoke-DSCResource

``` PowerShell
# Remove the Azure Devops Project and ensure that it is not recreated.
$properties = @{
    ProjectName             = 'MySameProject'
    Ensure                  = 'Absent'
}

Invoke-DSCResource -Name 'AzDoProject' -Method Set -Property $properties -ModuleName 'AzureDevOpsDsc'
```

## Example 4: Sample Configuration using xAzDoDSCDatum

``` YAML
parameters: {}

variables: {
  ProjectName: SampleProject,
  ProjectDescription: This is a SampleProject!   
}

resources:

  - name: Project
    type: AzureDevOpsDsc/AzDoProject
    properties:
      projectName: $ProjectName
      projectDescription: $ProjectDescription
      visibility: private
      SourceControlType: Git
      ProcessTemplate: Agile
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

.\Invoke-AZDOLCM.ps1 @params

```
