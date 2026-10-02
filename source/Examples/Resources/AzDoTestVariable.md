# DSC AzDoTestVariable Resource

## Syntax

```PowerShell
AzDoTestVariable [string] #ResourceName
{
    ProjectName            = [String]$ProjectName
    Name                   = [String]$Name
    [ Description          = [String]$Description ]
    [ Values               = [String[]]$Values ]
    [ Ensure               = [String] {'Present', 'Absent'} ]
}
```

## Properties

### Common Properties

- **ProjectName**: The name of the Azure DevOps project. Mandatory.
- **Name**: The name of the test variable. This is the key property, unique within the project.
- **Description**: A description of the test variable.
- **Values**: The allowed values for the variable, for example `@('Edge', 'Chrome', 'Firefox')`. Compared as a set - order does not matter.
- **Ensure**: Specifies whether the variable should exist. Valid values are `Present` and `Absent`.

## Additional Information

Test variables are the building blocks that `AzDoTestConfiguration` combines into concrete test configurations - declare the variable first and make configurations depend on it.

There is no test-plan security namespace. Managing who can create or edit test variables, configurations, plans and suites is covered by the existing `CSS` (area) permissions via `AzDoAreaPermission` - there is no `AzDoTestPlanPermission` resource.

## Examples

## Example 1: Sample Configuration using AzDoTestVariable Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    Node localhost {
        AzDoTestVariable Browser {
            Ensure      = 'Present'
            ProjectName = 'MyProject'
            Name        = 'Browser'
            Values      = @('Edge', 'Chrome', 'Firefox')
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoTestVariable
$properties = @{
    ProjectName = 'MyProject'
    Name        = 'Browser'
}

Invoke-DscResource -Name 'AzDoTestVariable' -Method Get -Property $properties -ModuleName 'AzureDevOpsDscNative'
```

## Example 3: Sample Configuration using Dsc.PipelineRunner

``` YAML
parameters: {}

variables: {
  ProjectName: MyProject
}

resources:
- name: Browser Test Variable
  type: AzureDevOpsDscNative/AzDoTestVariable
  dependsOn:
    - AzureDevOpsDscNative/AzDoProject/MyProject
  properties:
    ProjectName: $ProjectName
    Name: Browser
    Values:
      - Edge
      - Chrome
      - Firefox
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
