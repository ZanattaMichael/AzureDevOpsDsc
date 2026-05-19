# DSC AzDoPipelinePermission Resource

# Syntax

``` PowerShell
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

# Common Properties

- __ProjectName__: The name of the Azure DevOps project. This is a key property.
- __PipelineName__: The name of the pipeline. This is a key property.
- __GroupName__: The name of the group to grant permissions to. This is a key property. Use the format `[ProjectName]\GroupName`.
- __isInherited__: Whether permissions are inherited from the parent. Defaults to `$true`.
- __Permissions__: An array of permission hashtables specifying the permissions to grant or deny.
- __Ensure__: Specifies whether the permissions should exist. Valid values are `Present` and `Absent`. Defaults to `Present`.

## Permissions Syntax

``` PowerShell
AzDoPipelinePermission/Permissions
{
    Permission = [String]$PermissionName
    Access     = [String] {'Allow', 'Deny', 'NotSet'}
}
```

## Permission List

| Name | Description |
| ---- | ----------- |
| ViewBuilds | View builds |
| EditBuildQuality | Edit build quality |
| RetainIndefinitely | Retain indefinitely |
| DeleteBuilds | Delete builds |
| ManageBuildQualities | Manage build qualities |
| DestroyBuilds | Destroy builds |
| UpdateBuildInformation | Update build information |
| QueueBuilds | Queue builds |
| ManageBuildQueue | Manage build queue |
| StopBuilds | Stop builds |
| ViewBuildDefinition | View build pipeline |
| EditBuildDefinition | Edit build pipeline |
| DeleteBuildDefinition | Delete build pipeline |
| OverrideBuildCheckInValidation | Override check-in validation by build |
| AdministerBuildPermissions | Administer build permissions |

# Additional Information

This resource manages security permissions on individual Azure DevOps pipelines, controlling which groups can view, queue, or manage specific pipeline definitions.

# Examples

## Example 1: Grant pipeline permissions

``` PowerShell
New-AzDoAuthenticationProvider -OrganizationName 'test-organization' -PersonalAccessToken 'my-pat'

Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoPipelinePermission 'AddPipelinePermission' {
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
```
