# DSC AzDoSecureFile Resource

## Syntax

```PowerShell
AzDoSecureFile [string] #ResourceName
{
    ProjectName      = [String]$ProjectName
    SecureFileName   = [String]$SecureFileName
    [ FilePath       = [String]$FilePath ]
    [ Properties     = [HashTable]$Properties ]
    [ ForceUpload    = [Boolean]$ForceUpload ]
    [ Ensure         = [String] {'Present', 'Absent'} ]
}
```

## Properties

### Common Properties

- **ProjectName**: The name of the Azure DevOps project. Mandatory.
- **SecureFileName**: The name of the secure file in Azure DevOps. This is the key property.
- **FilePath**: The path of the local file to upload. Required when creating the secure file.
- **Properties**: Arbitrary key/value metadata stored alongside the file.
- **ForceUpload**: Re-upload the file on every run, replacing the stored content. Defaults to `$false`.
- **Ensure**: Specifies whether the secure file should exist. Valid values are `Present` and `Absent`.

## Additional Information

Secure files hold the secrets a pipeline needs but which do not belong in a variable group or in source control — certificates, keystores, provisioning profiles, signing keys.

### Content cannot be compared

Azure DevOps never returns a secure file's contents through the API. That is the entire point of the feature, but it means `Test()` can confirm that a file of the right name exists and that its properties match — **not** that the stored bytes still match the local file. A configuration whose local file has changed will report as being in the desired state.

`ForceUpload = $true` is the way to express "this content changes, replace it every run". It is off by default because it replaces the file on every single run.

### Replacing content changes the file's id

Azure DevOps has no API for updating a secure file's content in place, so `ForceUpload` deletes the existing file and uploads a new one. Two consequences:

- The secure file briefly does not exist. A pipeline running at that moment will fail to find it.
- The new file has a **new id**. Permissions and pipeline authorizations are granted against the id, so they must be re-applied — `AzDoSecureFilePermission` does this on its next run, which is why it is worth declaring alongside.

If the local file named by `FilePath` is missing, the resource refuses to delete the existing secure file rather than removing it and then failing to upload a replacement.

## Examples

## Example 1: Sample Configuration using AzDoSecureFile Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    Node localhost {
        AzDoSecureFile AddSigningCertificate {
            Ensure         = 'Present'
            ProjectName    = 'MyProject'
            SecureFileName = 'signing.pfx'
            FilePath       = 'C:\certs\signing.pfx'
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoSecureFile
$properties = @{
    ProjectName    = 'MyProject'
    SecureFileName = 'signing.pfx'
}

Invoke-DscResource -Name 'AzDoSecureFile' -Method Get -Property $properties -ModuleName 'AzureDevOpsDscNative'
```

## Example 3: Sample Configuration using Dsc.PipelineRunner

``` YAML
parameters: {}

variables: {
  ProjectName: MyProject
}

resources:
- name: Signing Certificate
  type: AzureDevOpsDscNative/AzDoSecureFile
  dependsOn:
    - AzureDevOpsDscNative/AzDoProject/MyProject
  properties:
    ProjectName: $ProjectName
    SecureFileName: signing.pfx
    FilePath: C:\certs\signing.pfx
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
