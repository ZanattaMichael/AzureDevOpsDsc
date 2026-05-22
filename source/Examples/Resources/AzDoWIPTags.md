# DSC AzDoWIPTags Resource

## Syntax

```PowerShell
AzDoWIPTags [string] #ResourceName
{
    ProjectName                 = [String]$ProjectName
    WorkItemTrackingTagList     = [String[]]$WorkItemTrackingTagList
}
```

## Properties

### Common Properties

- **ProjectName**: The name of the Azure DevOps project. This property is mandatory and serves as a key property for the resource.
- **WorkItemTrackingTagList**: An array of work item tracking tags to manage within the project.

## Additional Information

This resource manages work item tracking tags in Azure DevOps projects using Desired State Configuration (DSC). It enables the creation and management of tags that can be applied to work items within a specified project.

## Examples

## Example 1: Sample Configuration using AzDoWIPTags Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoWIPTags AddWIPTags {
            ProjectName             = 'MyProject'
            WorkItemTrackingTagList = @('Bug', 'Feature', 'Improvement')
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoWIPTags
$properties = @{
    ProjectName             = 'MyProject'
    WorkItemTrackingTagList = @('Bug', 'Feature', 'Improvement')
}

Invoke-DscResource -Name 'AzDoWIPTags' -Method Get -Property $properties -ModuleName 'AzureDevOpsDsc'
```

## Example 3: Sample Configuration using AzDO-DSC-LCM

``` YAML
parameters: {}

variables: {
  ProjectName: MyProject
}

resources:
- name: Work Item Tags
  type: AzureDevOpsDsc/AzDoWIPTags
  dependsOn:
    - AzureDevOpsDsc/AzDoProject/MyProject
  properties:
    ProjectName: $ProjectName
    WorkItemTrackingTagList:
      - Bug
      - Feature
      - Improvement
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
