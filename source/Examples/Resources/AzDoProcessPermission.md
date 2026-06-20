# DSC AzDoProcessPermission Resource

## Syntax

```PowerShell
AzDoProcessPermission [string] #ResourceName
{
    ProcessName   = [String]$ProcessName
    [ isInherited = [Boolean]$isInherited ]
    [ Permissions = [HashTable[]]$Permissions ]
    [ Ensure      = [String] {'Present', 'Absent'} ]
}
```

## Permissions Syntax

``` PowerShell
AzDoProcessPermission/Permissions
{
    Identity   = [String]$Identity # Syntax
    #   SYNTAX:     '[ProjectName | OrganizationName]\ServicePrincipalName, UserPrincipalName, UserDisplayName, GroupDisplayName'
    #   EXAMPLE:    '[SampleOrganizationName]\Process Authors'
    #   EXAMPLE:    '[]\Process Authors'   # organisation-level group
    Permission = [Hashtable]$Permissions # See 'Permission List'
}
```

## Permission Usage

``` PowerShell
AzDoProcessPermission/Permissions/Permission
{
    PermissionName|PermissionDisplayName = [String]$Name { 'Allow, Deny' }
}
```

## Permission List

> Either 'Name' or 'DisplayName' can be used, but we Strongly Recommend that you use 'Name' in your configuration.

| Name | DisplayName | Values | Note |
| ---- | ----------- | ------ | ---- |
| Create | Create process | [ allow, deny ] | Allows creating inherited (child) processes from existing ones. |
| Edit | Edit process | [ allow, deny ] | |
| Delete | Delete process | [ allow, deny ] | |
| AdministerProcessPermissions | Administer process permissions | [ allow, deny ] | |
| ReadProcessPermissions | Read process permissions | [ allow, deny ] | |

## Properties

### Common Properties

- **ProcessName**: The scope of the permissions. This is the key property. Use the sentinel value `AllProcesses` to target the organisation-wide root scope (`$PROCESS`), which governs who can create, edit, delete and administer processes — including creating inherited (child) processes. Use a specific inherited process name to scope permissions to that single process.
- **isInherited**: Whether the ACL inherits permissions from parent scopes. Defaults to `$true`.
- **Permissions**: A HashTable array that specifies the permissions to be set. Refer to: 'Permissions Syntax'.
- **Ensure**: Specifies whether the permissions should exist. Valid values are `Present` and `Absent`.

## Additional Information

This resource manages access control entries in the Azure DevOps **Process** security namespace. The most common use is granting a group the `Create` permission at the `AllProcesses` scope so its members can create inherited processes based on existing ones. System processes (Agile, Scrum, CMMI, Basic) have no per-process token; their create/administer security lives at the `AllProcesses` (root) scope.

## Examples

## Example 1: Allow a group to create child processes (org-wide)

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoProcessPermission AllowCreateProcesses {
            Ensure      = 'Present'
            ProcessName = 'AllProcesses'
            isInherited = $true
            Permissions = @(
                @{
                    Identity   = '[MyOrg]\Process Authors'
                    Permission = @{
                        'Create' = 'Allow'
                        'Edit'   = 'Allow'
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
# Return the current configuration for AzDoProcessPermission
$properties = @{
    ProcessName = 'AllProcesses'
    isInherited = $true
    Permissions = @(
        @{
            Identity   = '[MyOrg]\Process Authors'
            Permission = @{
                'Create' = 'Allow'
            }
        }
    )
}

Invoke-DscResource -Name 'AzDoProcessPermission' -Method Get -Property $properties -ModuleName 'AzureDevOpsDsc'
```

## Example 3: Sample Configuration using AzDO-DSC-LCM

``` YAML
parameters: {}

variables: {
  OrganizationName: MyOrg
}

resources:
- name: Allow Process Authors to create processes
  type: AzureDevOpsDsc/AzDoProcessPermission
  properties:
    ProcessName: AllProcesses
    isInherited: true
    Permissions:
      - Identity: '[$OrganizationName]\Process Authors'
        Permission:
          Create: Allow
          Edit: Allow
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
