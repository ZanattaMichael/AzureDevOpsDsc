# DSC AzDoAreaPermission Resource

# Syntax

``` PowerShell
AzDoAreaPermission [string] #ResourceName
{
    ProjectName = [String]$ProjectName
    [ AreaPath  = [String]$AreaPath ]
    [ isInherited = [Bool]$isInherited]
    Permissions = [HashTable]$Permissions # See Permissions Syntax
    [ Ensure = [String] {'Present', 'Absent'}]
}
```

## Permissions Syntax

``` PowerShell
AzDoAreaPermission/Permissions
{
    Identity = [String]$Identity # Syntax
    #   SYNTAX:     '[ProjectName | OrganizationName]\ServicePrincipalName, UserPrincipalName, UserDisplayName, GroupDisplayName'
    #   EXAMPLE:    '[TestProject]\UserName@email.com'
    #   EXAMPLE:    '[SampleOrganizationName]\Project Collection Administrators'
    Permission = [Hashtable[]]$Permissions # See 'Permission List"
}
```

## Permission Usage

``` PowerShell
AzDoAreaPermission/Permissions/Permission
{
    PermissionName|PermissionDisplayName = [String]$Name { 'Allow, Deny' }
}

```

## Permission List

> Either 'Name' or 'DisplayName' can be used, but we Strongly Recommend that you use 'Name' in your configuration.

| Name      | DisplayName      | Values | Note |
| ------------- | ------------- | - | - |
| GENERIC_READ | View permissions for this node | [ allow, deny ] | |
| GENERIC_WRITE | Edit this node | [ allow, deny ] | |
| CREATE_CHILDREN | Create child nodes | [ allow, deny ] | |
| DELETE | Delete this node | [ allow, deny ] | |
| WORK_ITEM_READ | View work items in this node | [ allow, deny ] | |
| WORK_ITEM_WRITE | Edit work items in this node | [ allow, deny ] | |
| MANAGE_TEST_PLANS | Manage test plans | [ allow, deny ] | |
| MANAGE_TEST_SUITES | Manage test suites | [ allow, deny ] | |
| WORK_ITEM_SAVE_COMMENT | Edit work item comments in this node | [ allow, deny ] | |

# Common Properties

- __ProjectName__: The name of the Azure DevOps project.
- __AreaPath__: The AreaPath.
- __isInherited__: Enforce or Break Inheritance on the ACL.
- __Permissions__: A HashTable that specifies the permissions to be set. Refer to: 'Permissions Syntax'.
- __Ensure__: Specifies whether the repository should exist. Defaults to 'Absent'.

# Additional Information

None

# Examples

## Example 1: Sample Configuration using AzDoAreaPermission Resource

``` PowerShell
Configuration ExampleConfig
{

    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoAreaPermission 'SetAzDoAreaPermission'
        {
            Ensure               = 'Present'
            ProjectName          = 'Test Project'
            AreaPath             = '\Test Area\Sub Area'
            isInherited          = $false
            Permissions          = @(
                @{
                    Identity   = '[Test Project]\Test Team'
                    Permission = @{
                        'WORK_ITEM_READ'  = 'Allow'
                        'GENERIC_WRITE'   = 'Allow'
                    }
                }
            )
        }
    }
}

ExampleConfig
Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose

```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoAreaPermission
# Ensure is not required
$properties = @{
    Ensure               = 'Present'
    ProjectName          = 'Test Project'
    AreaPath             = '\Test Area\Sub Area'
    isInherited          = $false
    Permissions          = @(
        @{
            Identity   = '[Test Project]\Test Team'
            Permission = @{
                'WORK_ITEM_READ'  = 'Allow'
                'GENERIC_WRITE'   = 'Allow'
            }
        }
    )
}

Invoke-DSCResource -Name 'AzDoAreaPermission' -Method Get -Property $properties -ModuleName 'AzureDevOpsDsc'
```

## Example 3: Sample Configuration using AzDO-DSC-LCM

``` YAML
parameters: {}

variables: {
  ProjectName: SampleProject,
  RepositoryName: SampleRepository
}

resources:

  - name: Sample AreaPath Permissions
    type: AzureDevOpsDsc/AzDoAreaPermission
    properties:
      projectName: $ProjectName
      AreaPath: '\Test Area\Sub Area'
      isInherited: false
      Permissions:
        - Identity: '[$ProjectName]\TestTeam'
          Permission:
            'Edit this node': "Allow"
            'Manage test suites': "Allow"
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
