# DSC AzDoSecurityNamespacePermission Resource

## Syntax

```PowerShell
AzDoSecurityNamespacePermission [string] #ResourceName
{
    SecurityNamespace = [String]$SecurityNamespace
    Token             = [String]$Token
    GroupName         = [String]$GroupName
    [ isInherited     = [Boolean]$isInherited ]
    [ Permissions     = [HashTable[]]$Permissions ]
    [ Ensure          = [String] {'Present', 'Absent'} ]
}
```

## Permissions Syntax

``` PowerShell
AzDoSecurityNamespacePermission/Permissions
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
AzDoSecurityNamespacePermission/Permissions/Permission
{
    PermissionName|PermissionDisplayName = [String]$Name { 'Allow, Deny' }
}
```

## Permission List

> **Note:** Available permissions depend on the `SecurityNamespace` specified. The permission names below are examples from commonly used namespaces. Use the Azure DevOps REST API (`/_apis/accesscontrolentries/{namespaceId}`) or the `az devops security permission namespace list` command to retrieve the full list of permissions for a specific namespace.

### Build Namespace (`Build`)

| Name | DisplayName | Values | Note |
| ---- | ----------- | ------ | ---- |
| ViewBuilds | View builds | [ allow, deny ] | |
| EditBuildQuality | Edit build quality | [ allow, deny ] | |
| RetainIndefinitely | Retain indefinitely | [ allow, deny ] | |
| DeleteBuilds | Delete builds | [ allow, deny ] | |
| QueueBuilds | Queue builds | [ allow, deny ] | |
| StopBuilds | Stop builds | [ allow, deny ] | |
| ViewBuildDefinition | View build pipeline | [ allow, deny ] | |
| EditBuildDefinition | Edit build pipeline | [ allow, deny ] | |
| DeleteBuildDefinition | Delete build pipeline | [ allow, deny ] | |
| AdministerBuildPermissions | Administer build permissions | [ allow, deny ] | Not recommended. |

### Git Repositories Namespace (`Git Repositories`)

| Name | DisplayName | Values | Note |
| ---- | ----------- | ------ | ---- |
| GenericRead | Read | [ allow, deny ] | |
| GenericContribute | Contribute | [ allow, deny ] | |
| ForcePush | Force push (rewrite history, delete branches, and files) | [ allow, deny ] | |
| CreateBranch | Create branch | [ allow, deny ] | |
| CreateTag | Create tag | [ allow, deny ] | |
| ManageNote | Manage notes | [ allow, deny ] | |
| PolicyExempt | Bypass policies when pushing | [ allow, deny ] | Not recommended. |
| CreateRepository | Create repository | [ allow, deny ] | |
| DeleteRepository | Delete repository | [ allow, deny ] | Not recommended. |
| ManagePermissions | Manage permissions | [ allow, deny ] | Not recommended. |

### Project Namespace (`Project`)

| Name | DisplayName | Values | Note |
| ---- | ----------- | ------ | ---- |
| GENERIC_READ | View project-level information | [ allow, deny ] | |
| GENERIC_WRITE | Edit project-level information | [ allow, deny ] | |
| DELETE | Delete team project | [ allow, deny ] | Not recommended. |
| WORK_ITEM_DELETE | Delete and restore work items | [ allow, deny ] | |
| WORK_ITEM_MOVE | Move work items out of this project | [ allow, deny ] | |
| RENAME | Rename team project | [ allow, deny ] | |
| BYPASS_RULES | Bypass rules on work item updates | [ allow, deny ] | |

## Properties

### Common Properties

- **SecurityNamespace**: The name of the Azure DevOps security namespace (e.g., `Build`, `Git Repositories`, `Project`). This property is mandatory and serves as a key property for the resource.
- **Token**: The security token identifying the specific object within the namespace. This is a key property.
- **GroupName**: The name of the group to grant permissions to. This is a key property. Use the format `[ProjectName]\GroupName`.
- **isInherited**: Whether permissions are inherited. Defaults to `$true`.
- **Permissions**: A HashTable that specifies the permissions to be set. Refer to: 'Permissions Syntax'.
- **Ensure**: Specifies whether the permissions should exist. Valid values are `Present` and `Absent`.

## Additional Information

This resource provides low-level access to Azure DevOps security namespaces, allowing fine-grained permission control over any object in the system. For most use cases, prefer the higher-level permission resources (e.g., `AzDoGitPermission`, `AzDoPipelinePermission`). Use this resource when you need to control permissions for namespaces not covered by dedicated resources.

## Examples

## Example 1: Sample Configuration using AzDoSecurityNamespacePermission Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoSecurityNamespacePermission AddNamespacePermission {
            Ensure            = 'Present'
            SecurityNamespace = 'Build'
            Token             = 'repoV2/00000000-0000-0000-0000-000000000001'
            GroupName         = '[MyProject]\Contributors'
            isInherited       = $true
            Permissions       = @(
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
# Return the current configuration for AzDoSecurityNamespacePermission
$properties = @{
    SecurityNamespace = 'Build'
    Token             = 'repoV2/00000000-0000-0000-0000-000000000001'
    GroupName         = '[MyProject]\Contributors'
    isInherited       = $true
    Permissions       = @(
        @{
            Identity   = '[MyProject]\Contributors'
            Permission = @{
                'ViewBuilds' = 'Allow'
            }
        }
    )
}

Invoke-DscResource -Name 'AzDoSecurityNamespacePermission' -Method Get -Property $properties -ModuleName 'AzureDevOpsDsc'
```

## Example 3: Sample Configuration using AzDO-DSC-LCM

``` YAML
parameters: {}

variables: {
  ProjectName: MyProject,
  SecurityToken: 'repoV2/00000000-0000-0000-0000-000000000001'
}

resources:
- name: Build Namespace Contributors Permission
  type: AzureDevOpsDsc/AzDoSecurityNamespacePermission
  properties:
    SecurityNamespace: Build
    Token: $SecurityToken
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
