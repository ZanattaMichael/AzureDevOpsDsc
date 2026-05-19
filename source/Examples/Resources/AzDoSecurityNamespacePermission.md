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

## Properties

### Common Properties

- **SecurityNamespace**: The name of the Azure DevOps security namespace (e.g., `Build`, `Git Repositories`, `Project`). This property is mandatory and serves as a key property for the resource.
- **Token**: The security token identifying the specific object within the namespace. This is a key property.
- **GroupName**: The name of the group to grant permissions to. This is a key property. Use the format `[ProjectName]\GroupName`.
- **isInherited**: Whether permissions are inherited. Defaults to `$true`.
- **Permissions**: An array of permission hashtables specifying the permissions to grant or deny.
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
# Return the current configuration for AzDoSecurityNamespacePermission
$properties = @{
    SecurityNamespace = 'Build'
    Token             = 'repoV2/00000000-0000-0000-0000-000000000001'
    GroupName         = '[MyProject]\Contributors'
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
