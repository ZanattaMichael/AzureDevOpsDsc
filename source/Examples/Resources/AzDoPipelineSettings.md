# DSC AzDoPipelineSettings Resource

## Syntax

```PowerShell
AzDoPipelineSettings [string] #ResourceName
{
    ProjectName                          = [String]$ProjectName
    [ EnforceJobAuthScope               = [Boolean]$EnforceJobAuthScope ]
    [ EnforceJobAuthScopeForReleases    = [Boolean]$EnforceJobAuthScopeForReleases ]
    [ EnforceReferencedRepoScopedToken  = [Boolean]$EnforceReferencedRepoScopedToken ]
    [ EnforceSettableVar                = [Boolean]$EnforceSettableVar ]
    [ PublishPipelineMetadata           = [Boolean]$PublishPipelineMetadata ]
    [ StatusBadgesArePrivate            = [Boolean]$StatusBadgesArePrivate ]
    [ DisableClassicPipelineCreation    = [Boolean]$DisableClassicPipelineCreation ]
    [ DisableImpliedYAMLCiTrigger       = [Boolean]$DisableImpliedYAMLCiTrigger ]
    [ Ensure                           = [String] {'Present', 'Absent'} ]
}
```

## Properties

### Common Properties

- **ProjectName**: The name of the Azure DevOps project. This property is mandatory and serves as the key property for the resource.
- **EnforceJobAuthScope**: Limit job authorization scope to the current project for non-release pipelines.
- **EnforceJobAuthScopeForReleases**: Limit job authorization scope to the current project for release pipelines.
- **EnforceReferencedRepoScopedToken**: Protect access to repositories in YAML pipelines.
- **EnforceSettableVar**: Limit variables that can be set at queue time.
- **PublishPipelineMetadata**: Publish metadata from pipelines.
- **StatusBadgesArePrivate**: Disable anonymous access to status badges.
- **DisableClassicPipelineCreation**: Disable creation of classic build and release pipelines.
- **DisableImpliedYAMLCiTrigger**: Disable implied YAML CI triggers.
- **Ensure**: Specifies the desired state. These settings are intrinsic to a project and cannot be removed, so `Absent` is a no-op.

## Additional Information

This resource manages a project's pipeline general settings (Project Settings → Pipelines → Settings). Only the settings you explicitly specify are reconciled; any setting you omit is left untouched.

## Examples

## Example 1: Sample Configuration using AzDoPipelineSettings Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    Node localhost {
        AzDoPipelineSettings HardenPipelines {
            Ensure                           = 'Present'
            ProjectName                      = 'MyProject'
            EnforceJobAuthScope              = $true
            EnforceReferencedRepoScopedToken = $true
            StatusBadgesArePrivate           = $true
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoPipelineSettings
$properties = @{
    ProjectName         = 'MyProject'
    EnforceJobAuthScope = $true
}

Invoke-DscResource -Name 'AzDoPipelineSettings' -Method Get -Property $properties -ModuleName 'AzureDevOpsDsc'
```

## Example 3: Sample Configuration using AzDO-DSC-LCM

``` YAML
parameters: {}

variables: {
  ProjectName: MyProject
}

resources:
- name: Harden pipeline settings
  type: AzureDevOpsDsc/AzDoPipelineSettings
  dependsOn:
    - AzureDevOpsDsc/AzDevOpsProject/MyProject
  properties:
    ProjectName: $ProjectName
    EnforceJobAuthScope: true
    EnforceReferencedRepoScopedToken: true
    StatusBadgesArePrivate: true
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
