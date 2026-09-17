# DSC AzDoSecureFilePermission Resource

## Syntax

```PowerShell
AzDoSecureFilePermission [string] #ResourceName
{
    ProjectName        = [String]$ProjectName
    [ SecureFileName   = [String]$SecureFileName ]
    [ isInherited      = [Boolean]$isInherited ]
    [ Permissions      = [HashTable[]]$Permissions ]
    [ Ensure           = [String] {'Present', 'Absent'} ]
}
```

## Properties

### Common Properties

- **ProjectName**: The name of the Azure DevOps project. This is the key property.
- **SecureFileName**: The name of the secure file. Omit to target the project's Library root, which is the parent of every secure file and variable group in the project.
- **isInherited**: Whether the ACL inherits permissions from its parent. Defaults to `$true`.
- **Permissions**: The access control entries: `@{ Identity = '[ProjectName]\GroupName'; Permission = @{ View = 'Allow' } }`.
- **Ensure**: `Present` applies the permissions; `Absent` removes the ACL so the file falls back to inheriting.

## Additional Information

Secure files are secured by the **`Library`** namespace — the same one that secures variable groups. They carry their own token segment: `Library/Project/{projectId}/SecureFile/{secureFileId}`, as against `Library/Project/{projectId}/VariableGroup/{variableGroupId}`.

That shared namespace matters when targeting the project Library root: an ACL at the root is the one with *neither* a secure file nor a variable group segment, so both are excluded when comparing.

Because the token is built from the secure file's id, replacing a secure file's content (which creates a new id — see `AzDoSecureFile`) invalidates any permission granted against the old one. Declaring this resource alongside `AzDoSecureFile` with `DependsOn` means the permission is re-applied on the next run.

Permission action names come from the namespace itself. Read them from `_apis/securitynamespaces/{namespaceId}` rather than assuming a fixed set.

`Ensure = 'Absent'` on the project Library root is refused: it has no parent to inherit from.

## Examples

## Example 1: Sample Configuration using AzDoSecureFilePermission Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    Node localhost {
        AzDoSecureFilePermission SigningCertificatePermissions {
            ProjectName    = 'MyProject'
            SecureFileName = 'signing.pfx'
            isInherited    = $true
            Permissions    = @(
                @{
                    Identity   = '[MyProject]\Release Managers'
                    Permission = @{ View = 'Allow'; Use = 'Allow' }
                }
            )
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoSecureFilePermission
$properties = @{
    ProjectName    = 'MyProject'
    SecureFileName = 'signing.pfx'
    isInherited    = $true
}

Invoke-DscResource -Name 'AzDoSecureFilePermission' -Method Get -Property $properties -ModuleName 'AzureDevOpsDscNative'
```

## Example 3: Sample Configuration using Dsc.PipelineRunner

``` YAML
parameters: {}

variables: {
  ProjectName: MyProject
}

resources:
- name: Signing Certificate Permissions
  type: AzureDevOpsDscNative/AzDoSecureFilePermission
  dependsOn:
    - AzureDevOpsDscNative/AzDoSecureFile/Signing Certificate
  properties:
    ProjectName: $ProjectName
    SecureFileName: signing.pfx
    isInherited: true
    Permissions:
      - Identity: '[MyProject]\Release Managers'
        Permission:
          View: Allow
          Use: Allow
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
