# DSC AzDoVariableGroup Resource

## Syntax

```PowerShell
AzDoVariableGroup [string] #ResourceName
{
    ProjectName         = [String]$ProjectName
    VariableGroupName   = [String]$VariableGroupName
    [ Description       = [String]$Description ]
    [ VariableGroupType = [String] {'Vsts', 'AzureKeyVault'} ]
    [ Variables         = [HashTable]$Variables ]
    [ AllowAccess       = [Boolean]$AllowAccess ]
    [ Ensure            = [String] {'Present', 'Absent'} ]
}
```

## Properties

### Common Properties

- **ProjectName**: The name of the Azure DevOps project. This property is mandatory and serves as a key property for the resource.
- **VariableGroupName**: The name of the variable group. This is a key property.
- **Description**: An optional description for the variable group.
- **VariableGroupType**: The type of variable group. Valid values are `Vsts` (standard) and `AzureKeyVault`. Defaults to `Vsts`.
- **Variables**: A hashtable of key-value pairs representing the variables.
- **AllowAccess**: Whether all pipelines can access this variable group. Defaults to `$false`.
- **Ensure**: Specifies whether the variable group should exist. Valid values are `Present` and `Absent`.

## Additional Information

This resource manages variable groups in Azure DevOps, allowing shared variables and secrets to be used across multiple pipelines within a project.

## Examples

## Example 1: Sample Configuration using AzDoVariableGroup Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoVariableGroup AddVariableGroup {
            Ensure            = 'Present'
            ProjectName       = 'MyProject'
            VariableGroupName = 'MyVariableGroup'
            Description       = 'Shared pipeline variables'
            VariableGroupType = 'Vsts'
            AllowAccess       = $true
            Variables         = @{
                APP_ENV       = 'production'
                APP_LOG_LEVEL = 'warn'
            }
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoVariableGroup
$properties = @{
    ProjectName       = 'MyProject'
    VariableGroupName = 'MyVariableGroup'
}

Invoke-DscResource -Name 'AzDoVariableGroup' -Method Get -Property $properties -ModuleName 'AzureDevOpsDsc'
```

## Example 3: Sample Configuration using AzDO-DSC-LCM

``` YAML
parameters: {}

variables: {
  ProjectName: MyProject,
  VariableGroupName: MyVariableGroup
}

resources:
- name: My Variable Group
  type: AzureDevOpsDsc/AzDoVariableGroup
  dependsOn:
    - AzureDevOpsDsc/AzDevOpsProject/MyProject
  properties:
    ProjectName: $ProjectName
    VariableGroupName: $VariableGroupName
    Description: Shared pipeline variables
    VariableGroupType: Vsts
    AllowAccess: true
    Variables:
      APP_ENV: production
      APP_LOG_LEVEL: warn
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
