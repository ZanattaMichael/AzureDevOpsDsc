# DSC AzDoGitPermission Resource

## Syntax

``` PowerShell
AzDoGitPermission [string] #ResourceName
{
    ProjectName          = [String]$ProjectName
    [ RepositoryName     = [String]$RepositoryName ]
    [ isInherited        = [Boolean]$isInherited ]
    [ Permissions        = [HashTable[]]$Permissions ]
    [ Ensure             = [String] {'Present', 'Absent'} ]
}
```

The `RepositoryName` property is optional. If it is not provided, the Git permissions will be applied at the project-level.

## Permissions Syntax

``` PowerShell
AzDoGitPermission/Permissions
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
AzDoGitPermission/Permissions/Permission
{
    PermissionName|PermissionDisplayName = [String]$Name { 'Allow, Deny' }
}
```

## Permission List

> Either 'Name' or 'DisplayName' can be used, but we Strongly Recommend that you use 'Name' in your configuration.

| Name      | DisplayName      | Values | Note |
| ------------- | ------------- | - | - |
|Administer  |            Administer   | [ allow, deny ] | Not recommended. |
|GenericRead |            Read         | [ allow, deny ] | |
|GenericContribute |      Contribute | [ allow, deny ] | |
|ForcePush         |      Force push (rewrite history, delete branches and tags) | [ allow, deny ] | |
|CreateBranch      |     Create branch                                          |[ allow, deny ] | |
|CreateTag         |      Create tag                                            | [ allow, deny ] | |
|ManageNote        |      Manage notes                                          | [ allow, deny ] | |
|PolicyExempt      |      Bypass policies when pushing                          | [ allow, deny ] | |
|CreateRepository  |      Create repository                                     | [ allow, deny ] | |
|DeleteRepository  |      Delete or disable repository                          | [ allow, deny ] | |
|RenameRepository  |      Rename repository                                     | [ allow, deny ] | |
|EditPolicies      |      Edit policies                                         | [ allow, deny ] | |
|RemoveOthersLocks |      Remove others' locks                                  | [ allow, deny ] | |
|ManagePermissions |      Manage permissions                                    | [ allow, deny ] | |
|PullRequestContribute |   Contribute to pull requests                          |  [ allow, deny ] | |
|PullRequestBypassPolicy | Bypass policies when completing pull requests        |  [ allow, deny ] | |
|ViewAdvSecAlerts      |  Advanced Security: view alerts                        | [ allow, deny ] | |
|DismissAdvSecAlerts   |  Advanced Security: manage and dismiss alerts          | [ allow, deny ] | |
|ManageAdvSecScanning  |  Advanced Security: manage settings                    | [ allow, deny ] | |

# Common Properties

- __ProjectName__: The name of the Azure DevOps project.
- __RepositoryName__: The name of the Git repository within the project.
- __Permissions__: A HashTable that specifies the permissions to be set. Refer to: 'Permissions Syntax'.
- __Ensure__: Specifies whether the Git repository permissions should be applied. Defaults to 'Present'.

# Additional Information

This resource allows you to manage Git repository permissions in Azure DevOps using Desired State Configuration (DSC).
It includes properties for specifying the project name, repository name, permission inheritance, and a list of permissions to apply to identities.

# Examples

## Example 1: Sample Configuration using AzDoGitPermission Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoGitPermission AddGitPermission {
            Ensure         = 'Present'
            ProjectName    = 'MyProject'
            RepositoryName = 'MyRepository'
            isInherited    = $true
            Permissions    = @(
                @{
                    Identity   = '[MyProject]\Contributors'
                    Permission = @{
                        'GenericRead'        = 'Allow'
                        'GenericContribute'  = 'Allow'
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
# Return the current configuration for AzDoGitPermission
$properties = @{
    ProjectName    = 'MyProject'
    RepositoryName = 'MyRepository'
    isInherited    = $true
    Permissions    = @(
        @{
            Identity   = '[MyProject]\Contributors'
            Permission = @{
                'GenericRead' = 'Allow'
            }
        }
    )
}

Invoke-DscResource -Name 'AzDoGitPermission' -Method Get -Property $properties -ModuleName 'AzureDevOpsDsc'
```

## Example 3: Sample Configuration using AzDO-DSC-LCM

``` YAML
parameters: {}

variables: {
  ProjectName: MyProject,
  RepositoryName: MyRepository
}

resources:
- name: Repository Contributors Permissions
  type: AzureDevOpsDsc/AzDoGitPermission
  dependsOn:
    - AzureDevOpsDsc/AzDoGitRepository/MyRepository
  properties:
    ProjectName: $ProjectName
    RepositoryName: $RepositoryName
    isInherited: true
    Permissions:
      - Identity: '[$ProjectName]\Contributors'
        Permission:
          GenericRead: Allow
          GenericContribute: Allow
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
