# DSC AzDoIterationPermission Resource

# Syntax

``` PowerShell
AzDoIterationPermission [string] #ResourceName
{
    ProjectName = [String]$ProjectName
    [ IterationPath  = [String]$IterationPath ]
    [ isInherited = [Bool]$isInherited]
    Permissions = [HashTable]$Permissions # See Permissions Syntax
    [ Ensure = [String] {'Present', 'Absent'}]
}
```

## Permissions Syntax

``` PowerShell
AzDoIterationPermission/Permissions
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
AzDoIterationPermission/Permissions/Permission
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

# Common Properties

- __ProjectName__: The name of the Azure DevOps project.
- __IterationPath__: The IterationPath.
- __isInherited__: Enforce or Break Inheritance on the ACL.
- __Permissions__: A HashTable that specifies the permissions to be set. Refer to: 'Permissions Syntax'.
- __Ensure__: Specifies whether the repository should exist. Defaults to 'Absent'.

# Additional Information

None

# Examples

## Example 1: Sample Configuration using AzDoIterationPermission Resource

``` PowerShell
Configuration ExampleConfig
{

    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDoIterationPermission 'SetAzDoIterationPermission'
        {
            Ensure               = 'Present'
            ProjectName          = 'Test Project'
            IterationPath             = '\Test Iteration\Sub Iteration'
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
# Return the current configuration for AzDoIterationPermission
# Ensure is not required
$properties = @{
    Ensure               = 'Present'
    ProjectName          = 'Test Project'
    IterationPath             = '\Test Iteration\Sub Iteration'
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

Invoke-DSCResource -Name 'AzDoIterationPermission' -Method Get -Property $properties -ModuleName 'AzureDevOpsDsc'
```

## Example 3: Sample Configuration using AzDO-DSC-LCM

``` YAML
parameters: {}

variables: {
  ProjectName: SampleProject,
  RepositoryName: SampleRepository
}

resources:

  - name: Sample IterationPath Permissions
    type: AzureDevOpsDsc/AzDoIterationPermission
    properties:
      projectName: $ProjectName
      IterationPath: '\Test Iteration\Sub Iteration'
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
