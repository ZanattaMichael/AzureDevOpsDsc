# DSC AzDoGroupPermission Resource

## Syntax

```PowerShell
AzDoGroupPermission [string] #ResourceName
{
    GroupName     = [String]$GroupName
    [ isInherited = [Boolean]$isInherited ]
    [ Permissions = [HashTable[]]$Permissions ]
    [ Ensure      = [String] {'Present', 'Absent'} ]
}
```

## Permissions Syntax

``` PowerShell
AzDoGroupPermission/Permissions
{
    Identity   = [String]$Identity # Syntax
    #   SYNTAX:     '[ProjectName | OrganizationName]\ServicePrincipalName, UserPrincipalName, UserDisplayName, GroupDisplayName'
    #   ALTERNATIVE: 'this' refers to the group itself.
    #   EXAMPLE:    '[TestProject]\UserName@email.com'
    #   EXAMPLE:    '[SampleOrganizationName]\Project Collection Administrators'
    Permission = [Hashtable]$Permissions # See 'Permission List'
}
```

## Permission Usage

``` PowerShell
AzDoGroupPermission/Permissions/Permission
{
    PermissionName|PermissionDisplayName = [String]$Name { 'Allow, Deny' }
}
```

## Permission List

> Either 'Name' or 'DisplayName' can be used, but we Strongly Recommend that you use 'Name' in your configuration.

| Name | DisplayName | Values | Note |
| ---- | ----------- | ------ | ---- |
| Read | View identity information | [ allow, deny ] | |
| Write | Edit identity information | [ allow, deny ] | |
| Delete | Delete identity information | [ allow, deny ] | |
| ManageMembership | Manage group membership | [ allow, deny ] | |
| CreateScope | Create identity scopes | [ allow, deny ] | |
| RestoreScope | Restore identity scopes | [ allow, deny ] | |

## Properties

### Common Properties

- **GroupName**: The name of the Azure DevOps group. This property is mandatory and serves as the key property for the resource. Use the format `[ProjectName]\GroupName`.
- **isInherited**: Whether permissions are inherited. Defaults to `$true`.
- **Permissions**: A HashTable that specifies the permissions to be set. Refer to: 'Permissions Syntax'.
- **Ensure**: Specifies whether the permissions should exist. Valid values are `Present` and `Absent`.

## Additional Information

This resource manages permissions on Azure DevOps groups (identity security namespace), controlling what operations can be performed on the group itself such as managing membership or viewing group information.

## Examples

## Example 1: Sample Configuration using AzDoGroupPermission Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoGroupPermission AddGroupPermission {
            Ensure      = 'Present'
            GroupName   = '[MyProject]\Readers'
            isInherited = $true
            Permissions = @(
                @{
                    Identity   = '[MyProject]\Readers'
                    Permission = @{
                        'Read'            = 'Allow'
                        'ManageMembership' = 'Deny'
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
# Return the current configuration for AzDoGroupPermission
$properties = @{
    GroupName   = '[MyProject]\Readers'
    isInherited = $true
    Permissions = @(
        @{
            Identity   = '[MyProject]\Readers'
            Permission = @{
                'Read' = 'Allow'
            }
        }
    )
}

Invoke-DscResource -Name 'AzDoGroupPermission' -Method Get -Property $properties -ModuleName 'AzureDevOpsDsc'
```

## Example 3: Sample Configuration using AzDO-DSC-LCM

``` YAML
parameters: {}

variables: {
  ProjectName: MyProject
}

resources:
- name: Readers Group Permission
  type: AzureDevOpsDsc/AzDoGroupPermission
  dependsOn:
    - AzureDevOpsDsc/AzDoProjectGroup/Readers
  properties:
    GroupName: '[$ProjectName]\Readers'
    isInherited: true
    Permissions:
      - Identity: '[$ProjectName]\Readers'
        Permission:
          Read: Allow
          ManageMembership: Deny
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

## Additional Information

This resource inherits from `AzDevOpsDscResourceBase`, which provides the base functionality for DSC resources in the Azure DevOps DSC module. This resource is **not currently supported** and will be enabled in a future release.
