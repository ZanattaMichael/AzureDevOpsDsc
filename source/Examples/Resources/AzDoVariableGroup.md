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
    [ SharedWithProjects  = [String[]]$SharedWithProjects ]
    [ SharedNameOverrides = [HashTable]$SharedNameOverrides ]
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
- **SharedWithProjects**: Names of other projects to share this variable group with, in
  addition to `ProjectName`. Sharing is only compared and enforced when this property is
  set; a configuration that omits it leaves any existing sharing untouched. Dropping a
  project from this list unshares the variable group from it without deleting it.
- **SharedNameOverrides**: A hashtable of `ProjectName = DisplayName` giving the variable
  group a different name in a shared project. Only takes effect for names in
  `SharedWithProjects`; the owning project's reference always uses `VariableGroupName`.
- **Ensure**: Specifies whether the variable group should exist. Valid values are `Present` and `Absent`.

## Additional Information

This resource manages variable groups in Azure DevOps, allowing shared variables and secrets to be used across multiple pipelines within a project.

Removing a shared variable group from its owning project removes it from every project it
is shared with — Azure DevOps has no operation to hand ownership to another project
instead. `Remove-AzDoVariableGroup` warns and names the other projects when this applies,
but still proceeds; unshare the projects you want to keep it available to first (set
`SharedWithProjects` to just the ones that should keep it, or empty it out) if that is not
what you want.

Permissions set via `AzDoVariableGroupPermission` are unaffected by sharing: the ACL token
is anchored to the owning project and the variable group's own id, regardless of how many
other projects it is shared with.

## Examples

## Example 1: Sample Configuration using AzDoVariableGroup Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

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

Invoke-DscResource -Name 'AzDoVariableGroup' -Method Get -Property $properties -ModuleName 'AzureDevOpsDscNative'
```

## Example 3: Sharing a variable group with another project

``` PowerShell
Configuration ExampleSharedConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    Node localhost {
        AzDoVariableGroup ShareVariableGroup {
            Ensure               = 'Present'
            ProjectName          = 'MyProject'
            VariableGroupName    = 'CommonSettings'
            Variables            = @{
                APP_ENV = 'production'
            }
            SharedWithProjects   = @('OtherProject')
            SharedNameOverrides  = @{
                OtherProject = 'CommonSettings (from MyProject)'
            }
        }
    }
}

Start-DscConfiguration -Path ./ExampleSharedConfig -Wait -Verbose
```

## Example 4: Sample Configuration using Dsc.PipelineRunner

``` YAML
parameters: {}

variables: {
  ProjectName: MyProject,
  VariableGroupName: MyVariableGroup
}

resources:
- name: My Variable Group
  type: AzureDevOpsDscNative/AzDoVariableGroup
  dependsOn:
    - AzureDevOpsDscNative/AzDoProject/MyProject
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
