# DSC AzDoQueryPermission Resource

## Syntax

```PowerShell
AzDoQueryPermission [string] #ResourceName
{
    ProjectName     = [String]$ProjectName
    [ QueryPath     = [String]$QueryPath ]
    [ isInherited   = [Boolean]$isInherited ]
    [ Permissions   = [HashTable[]]$Permissions ]
    [ Ensure        = [String] {'Present', 'Absent'} ]
}
```

## Properties

### Common Properties

- **ProjectName**: The name of the Azure DevOps project. This is the key property.
- **QueryPath**: The full path of the query folder, including the root — for example `Shared Queries/Platform`. Omit it to target the project's query root, which is the parent of every query in the project.
- **isInherited**: Whether the ACL inherits permissions from its parent. Defaults to `$true`.
- **Permissions**: The access control entries, as an array of hashtables: `@{ Identity = 'ProjectName\GroupName'; Permission  = @{ Read = 'Allow' } }`.
- **Ensure**: `Present` applies the permissions; `Absent` removes the folder's ACL so it falls back to inheriting from its parent.

## Additional Information

This resource uses the `WorkItemQueryFolders` security namespace. Permissions are administered on folders and inherited by the queries beneath them, which is how query security is normally organised.

The ACL token addresses folders by **GUID**, not by name: `$/{projectId}/{folderId}/{subfolderId}`. The resource resolves the readable path to that chain of ids before building the token, so a folder renamed in the UI still resolves as long as the configured path matches. The comparison is order-sensitive — the token is a path, so the same ids in a different order describe a different folder.

Permission action names (`Read`, `Contribute`, `Delete`, `ManagePermissions`) come from the namespace itself. Read them from `_apis/securitynamespaces/{namespaceId}` rather than assuming a fixed set, since they differ per namespace and have changed between API versions.

`Ensure = 'Absent'` on the project query root is refused: that token has no parent to inherit from, so clearing it would leave every query in the project without an explicit grant.

Like the other hierarchical-namespace permission resources (`AzDoAreaPermission`, `AzDoIterationPermission`, `AzDoPipelinePermission`), evaluating this resource can be slow when the ACL fetch cannot be scoped to the token and falls back to reading the namespace in full.

## Examples

## Example 1: Sample Configuration using AzDoQueryPermission Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    Node localhost {
        AzDoQueryPermission PlatformQueries {
            ProjectName = 'MyProject'
            QueryPath   = 'Shared Queries/Platform'
            isInherited = $true
            Permissions = @(
                @{
                    Identity    = '[MyProject]\Platform Team'
                    Permission  = @{ Read = 'Allow'; Contribute = 'Allow' }
                }
            )
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoQueryPermission
$properties = @{
    ProjectName = 'MyProject'
    QueryPath   = 'Shared Queries/Platform'
    isInherited = $true
}

Invoke-DscResource -Name 'AzDoQueryPermission' -Method Get -Property $properties -ModuleName 'AzureDevOpsDscNative'
```

## Example 3: Sample Configuration using Dsc.PipelineRunner

``` YAML
parameters: {}

variables: {
  ProjectName: MyProject
}

resources:
- name: Platform Query Permissions
  type: AzureDevOpsDscNative/AzDoQueryPermission
  dependsOn:
    - AzureDevOpsDscNative/AzDoQueryFolder/Platform Query Folder
  properties:
    ProjectName: $ProjectName
    QueryPath: Shared Queries/Platform
    isInherited: true
    Permissions:
      - Identity: '[MyProject]\Platform Team'
        Permission:
          Read: Allow
          Contribute: Allow
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
