# DSC AzDoTestConfiguration Resource

## Syntax

```PowerShell
AzDoTestConfiguration [string] #ResourceName
{
    ProjectName            = [String]$ProjectName
    Name                   = [String]$Name
    [ Description          = [String]$Description ]
    [ IsDefault             = [Boolean]$IsDefault ]
    [ State                 = [String] {'active', 'inactive'} ]
    [ Values               = [String[]]$Values ]
    [ Ensure               = [String] {'Present', 'Absent'} ]
}
```

## Properties

### Common Properties

- **ProjectName**: The name of the Azure DevOps project. Mandatory.
- **Name**: The name of the test configuration. This is the key property, unique within the project.
- **Description**: A description of the configuration.
- **IsDefault**: Whether new test plans/suites should use this configuration by default. Defaults to `$false`.
- **State**: `active` or `inactive`. Defaults to `active`.
- **Values**: The variable/value pairs that make up the configuration, each written as `'VariableName=Value'` (for example `'Browser=Edge'`, `'OS=Windows 11'`). Each `VariableName` must be an existing `AzDoTestVariable` in the project, and each value must be one of that variable's allowed values.
- **Ensure**: Specifies whether the configuration should exist. Valid values are `Present` and `Absent`.

## Additional Information

Every pair in `Values` must reference a test variable that already exists in the project, and a value that variable allows - the resource validates both and fails with a clear message when either is missing, rather than letting the API's generic error stand in for it.

There is no test-plan security namespace. Managing who can create or edit test configurations is covered by the existing `CSS` (area) permissions via `AzDoAreaPermission` - there is no `AzDoTestPlanPermission` resource.

## Examples

## Example 1: Sample Configuration using AzDoTestConfiguration Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    Node localhost {
        AzDoTestVariable Browser {
            Ensure      = 'Present'
            ProjectName = 'MyProject'
            Name        = 'Browser'
            Values      = @('Edge', 'Chrome')
        }

        AzDoTestVariable OS {
            Ensure      = 'Present'
            ProjectName = 'MyProject'
            Name        = 'OS'
            Values      = @('Windows 11', 'macOS')
        }

        AzDoTestConfiguration Windows11Edge {
            Ensure      = 'Present'
            ProjectName = 'MyProject'
            Name        = 'Windows 11 + Edge'
            Values      = @('Browser=Edge', 'OS=Windows 11')
            DependsOn   = '[AzDoTestVariable]Browser', '[AzDoTestVariable]OS'
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoTestConfiguration
$properties = @{
    ProjectName = 'MyProject'
    Name        = 'Windows 11 + Edge'
}

Invoke-DscResource -Name 'AzDoTestConfiguration' -Method Get -Property $properties -ModuleName 'AzureDevOpsDscNative'
```

## Example 3: Sample Configuration using Dsc.PipelineRunner

``` YAML
parameters: {}

variables: {
  ProjectName: MyProject
}

resources:
- name: Windows 11 Edge Configuration
  type: AzureDevOpsDscNative/AzDoTestConfiguration
  dependsOn:
    - AzureDevOpsDscNative/AzDoTestVariable/Browser Test Variable
  properties:
    ProjectName: $ProjectName
    Name: Windows 11 + Edge
    Values:
      - Browser=Edge
      - OS=Windows 11
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
