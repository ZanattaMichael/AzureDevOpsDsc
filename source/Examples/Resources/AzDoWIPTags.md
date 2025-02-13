# DSC AzDoWIPTags Resource

## Syntax

```PowerShell
AzDoWIPTags [string] #ResourceName
{
    ProjectName = [String]$ProjectName
    WorkItemTrackingTagList = [String[]]$WorkItemTrackingTagList
}
```

## Properties

### Common Properties

- **ProjectName**: The name of the Azure DevOps project associated with this group. This property is mandatory.
- **WorkItemTrackingTagList**: An array of Tags to track.

## Additional Information

The AzDoWIPTags class is a DSC (Desired State Configuration) resource used for managing work item tags in Azure DevOps projects. It enables the creation, deletion, and listing of work item tags within a specified project.

### Example 1: Sample Configuration using AzDoWIPTags Resource

``` PowerShell
    configuration ExampleConfig {
        Import-DscResource -ModuleName AzDevOpsDsc

        Node 'localhost' {
            AzDoWIPTags AzDoWIPTagsExample {
                ProjectName              = "MyAzureDevOpsProject"
                WorkItemTrackingTagList  = @("Bug", "Feature", "Improvement")
            }
        }
    }

    # To apply the configuration:
    ExampleConfig -OutputPath "C:\DSC\ExampleConfig"
    Start-DscConfiguration -Path "C:\DSC\ExampleConfig" -Wait -Verbose
```

### Example 2: Sample Configuration using Invoke-DSCResource

```PowerShell
# Return the current configuration for AzDoProjectServices
# Ensure is not required
$properties = @{
    ProjectName      = 'SampleProject'
    WorkItemTrackingTagList  = @("Bug", "Feature", "Improvement")
}

Invoke-DSCResource -Name 'AzDoWIPTags' -Method Get -Property $properties -ModuleName 'AzureDevOpsDsc'
```

### Example 3: Sample Configuration using AzDO-DSC-LCM

```YAML
parameters: {}

variables: {
   "PlaceHolder2": "PlaceHolder"  
}

resources:
- name: Sample Project Services
  type: AzureDevOpsDsc/AzDoProjectServices
  properties:
    ProjectName: SampleProject
    WorkItemTrackingTagList: 
        "Bug",
        "Feature",
        "Improvement"
```

LCM Initialization:

```PowerShell

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
