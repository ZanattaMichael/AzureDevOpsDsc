# DSC AzDoGitPermission Resource

## Syntax

``` PowerShell
AzDoGitPermission [string] #ResourceName
{
    ProjectName          = [String]$ProjectName
    [ RepositoryName     = [String]$RepositoryName ]
    [ isInherited        = [Boolean]$isInherited ]
    [ BranchName         = [String]$BranchName ]
    [ TagName            = [String]$TagName ]
    [ Permissions        = [HashTable[]]$Permissions ]
    [ Ensure             = [String] {'Present', 'Absent'} ]
}
```

The `RepositoryName` property is optional. If it is not provided, the Git permissions will be applied at the project-level.

`BranchName` and `TagName` are optional and mutually exclusive, and both require `RepositoryName`.
Setting either one targets that single branch's or tag's own ACL (the `refs/heads/{BranchName}` or
`refs/tags/{TagName}` token) instead of the repository's ACL. Write the value as a bare ref name,
e.g. `main` or `release/1.0` - a leading `refs/heads/` (or `refs/tags/`) is accepted and stripped for
comparison, but the value written back is always what the configuration supplied.

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
- __BranchName__: Optional. Targets a single branch's ACL (`refs/heads/{BranchName}`) instead of the repository's ACL. Requires `RepositoryName`. Mutually exclusive with `TagName`.
- __TagName__: Optional. Targets a single tag's ACL (`refs/tags/{TagName}`) instead of the repository's ACL. Requires `RepositoryName`. Mutually exclusive with `BranchName`.
- __Permissions__: A HashTable that specifies the permissions to be set. Refer to: 'Permissions Syntax'.
- __Ensure__: Specifies whether the Git repository permissions should be applied. Defaults to 'Present'.

# Additional Information

This resource allows you to manage Git repository permissions in Azure DevOps using Desired State Configuration (DSC).
It includes properties for specifying the project name, repository name, permission inheritance, and a list of permissions to apply to identities.

# Examples

## Example 1: Sample Configuration using AzDoGitPermission Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

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

## Example 2: Denying force push on a single branch

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    Node localhost {
        AzDoGitPermission DenyForcePushOnMain {
            Ensure         = 'Present'
            ProjectName    = 'MyProject'
            RepositoryName = 'MyRepository'
            isInherited    = $false
            BranchName     = 'main'
            Permissions    = @(
                @{
                    Identity   = '[MyProject]\Contributors'
                    Permission = @{
                        'ForcePush' = 'Deny'
                    }
                }
            )
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 3: Sample Configuration using Invoke-DSCResource

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

Invoke-DscResource -Name 'AzDoGitPermission' -Method Get -Property $properties -ModuleName 'AzureDevOpsDscNative'
```

## Example 4: Sample Configuration using Dsc.PipelineRunner

``` YAML
parameters: {}

variables: {
  ProjectName: MyProject,
  RepositoryName: MyRepository
}

resources:
- name: Repository Contributors Permissions
  type: AzureDevOpsDscNative/AzDoGitPermission
  dependsOn:
    - AzureDevOpsDscNative/AzDoGitRepository/MyRepository
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

Pipeline runner initialization:

``` PowerShell

Import-Module Dsc.PipelineRunner

$params = @{
    AzureDevopsOrganizationName = "SampleAzDoOrgName"
    exportConfigDir             = "C:\Datum\DSCOutput\"
    ConfigurationSourcePath     = 'https://configuration-path'
    JITToken                    = 'SampleJITToken'
    Mode                        = 'Set'
    AuthenticationType          = 'ManagedIdentity'
    ReportPath                  = 'C:\Datum\DSCOutput\Reports'
}

Invoke-DscPipelineRunner @params
```
