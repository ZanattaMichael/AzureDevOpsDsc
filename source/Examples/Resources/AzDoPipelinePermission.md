# DSC AzDoPipelinePermission Resource

## Syntax

```PowerShell
AzDoPipelinePermission [string] #ResourceName
{
    ProjectName   = [String]$ProjectName
    PipelineName  = [String]$PipelineName
    GroupName     = [String]$GroupName
    [ isInherited = [Boolean]$isInherited ]
    [ Permissions = [HashTable[]]$Permissions ]
    [ Ensure      = [String] {'Present', 'Absent'} ]
}
```

## Properties

### Common Properties

- **ProjectName**: The name of the Azure DevOps project. This property is mandatory and serves as a key property for the resource.
- **PipelineName**: The name of the pipeline. This is a key property.
- **GroupName**: The name of the group to grant permissions to. This is a key property. Use the format `[ProjectName]\GroupName`.
- **isInherited**: Whether permissions are inherited from the parent. Defaults to `$true`.
- **Permissions**: An array of permission hashtables specifying the permissions to grant or deny.
- **Ensure**: Specifies whether the permissions should exist. Valid values are `Present` and `Absent`.

## Additional Information

This resource manages security permissions on individual Azure DevOps pipelines, controlling which groups can view, queue, or manage specific pipeline definitions.

## Examples

## Example 1: Sample Configuration using AzDoPipelinePermission Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoPipelinePermission AddPipelinePermission {
            Ensure       = 'Present'
            ProjectName  = 'MyProject'
            PipelineName = 'MyBuildPipeline'
            GroupName    = '[MyProject]\Contributors'
            isInherited  = $true
            Permissions  = @(
                @{ Permission = 'ViewBuilds'; Access = 'Allow' }
                @{ Permission = 'QueueBuilds'; Access = 'Allow' }
            )
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoPipelinePermission
$properties = @{
    ProjectName  = 'MyProject'
    PipelineName = 'MyBuildPipeline'
    GroupName    = '[MyProject]\Contributors'
    isInherited  = $true
    Permissions  = @(
        @{ Permission = 'ViewBuilds'; Access = 'Allow' }
    )
}

Invoke-DscResource -Name 'AzDoPipelinePermission' -Method Get -Property $properties -ModuleName 'AzureDevOpsDsc'
```

## Example 3: Sample Configuration using AzDO-DSC-LCM

``` YAML
parameters: {}

variables: {
  ProjectName: MyProject,
  PipelineName: MyBuildPipeline
}

resources:
- name: Pipeline Contributors Permission
  type: AzureDevOpsDsc/AzDoPipelinePermission
  dependsOn:
    - AzureDevOpsDsc/AzDoPipeline/MyBuildPipeline
  properties:
    ProjectName: $ProjectName
    PipelineName: $PipelineName
    GroupName: '[$ProjectName]\Contributors'
    isInherited: true
    Permissions:
      - Permission: ViewBuilds
        Access: Allow
      - Permission: QueueBuilds
        Access: Allow
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
