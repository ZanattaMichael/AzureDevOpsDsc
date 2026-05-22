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

## Permissions Syntax

``` PowerShell
AzDoPipelinePermission/Permissions
{
    Identity   = [String]$Identity # Syntax
    #   SYNTAX:     '[ProjectName | OrganizationName]\ServicePrincipalName, UserPrincipalName, UserDisplayName, GroupDisplayName'
    #   EXAMPLE:    '[TestProject]\UserName@email.com'
    #   EXAMPLE:    '[SampleOrganizationName]\Project Collection Administrators'
    Permission = [Hashtable]$Permissions # See 'Permission List'
}
```

## Permission Usage

``` PowerShell
AzDoPipelinePermission/Permissions/Permission
{
    PermissionName|PermissionDisplayName = [String]$Name { 'Allow, Deny' }
}
```

## Permission List

> Either 'Name' or 'DisplayName' can be used, but we Strongly Recommend that you use 'Name' in your configuration.

| Name | DisplayName | Values | Note |
| ---- | ----------- | ------ | ---- |
| ViewBuilds | View builds | [ allow, deny ] | |
| EditBuildQuality | Edit build quality | [ allow, deny ] | |
| RetainIndefinitely | Retain indefinitely | [ allow, deny ] | |
| DeleteBuilds | Delete builds | [ allow, deny ] | |
| ManageBuildQualities | Manage build qualities | [ allow, deny ] | |
| DestroyBuilds | Destroy builds | [ allow, deny ] | |
| UpdateBuildInformation | Update build information | [ allow, deny ] | |
| QueueBuilds | Queue builds | [ allow, deny ] | |
| ManageBuildQueue | Manage build queue | [ allow, deny ] | |
| StopBuilds | Stop builds | [ allow, deny ] | |
| ViewBuildDefinition | View build pipeline | [ allow, deny ] | |
| EditBuildDefinition | Edit build pipeline | [ allow, deny ] | |
| DeleteBuildDefinition | Delete build pipeline | [ allow, deny ] | |
| OverrideBuildCheckInValidation | Override check-in validation by build | [ allow, deny ] | |
| AdministerBuildPermissions | Administer build permissions | [ allow, deny ] | Not recommended. |

## Properties

### Common Properties

- **ProjectName**: The name of the Azure DevOps project. This property is mandatory and serves as a key property for the resource.
- **PipelineName**: The name of the pipeline. This is a key property.
- **GroupName**: The name of the group to grant permissions to. This is a key property. Use the format `[ProjectName]\GroupName`.
- **isInherited**: Whether permissions are inherited from the parent. Defaults to `$true`.
- **Permissions**: A HashTable that specifies the permissions to be set. Refer to: 'Permissions Syntax'.
- **Ensure**: Specifies whether the permissions should exist. Valid values are `Present` and `Absent`.

## Additional Information

This resource manages security permissions on individual Azure DevOps pipelines (build security namespace), controlling which groups can view, queue, or manage specific pipeline definitions.

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
                @{
                    Identity   = '[MyProject]\Contributors'
                    Permission = @{
                        'ViewBuilds'  = 'Allow'
                        'QueueBuilds' = 'Allow'
                    }
                }
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
        @{
            Identity   = '[MyProject]\Contributors'
            Permission = @{
                'ViewBuilds' = 'Allow'
            }
        }
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
      - Identity: '[$ProjectName]\Contributors'
        Permission:
          ViewBuilds: Allow
          QueueBuilds: Allow
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
