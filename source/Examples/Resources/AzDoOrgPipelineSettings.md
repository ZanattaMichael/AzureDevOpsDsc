# DSC AzDoOrgPipelineSettings Resource

## Syntax

```PowerShell
AzDoOrgPipelineSettings [string] #ResourceName
{
    OrganizationName                     = [String]$OrganizationName
    [ EnforceJobAuthScope               = [String] {'', 'true', 'false'} ]
    [ EnforceJobAuthScopeForReleases    = [String] {'', 'true', 'false'} ]
    [ EnforceReferencedRepoScopedToken  = [String] {'', 'true', 'false'} ]
    [ EnforceSettableVar                = [String] {'', 'true', 'false'} ]
    [ PublishPipelineMetadata           = [String] {'', 'true', 'false'} ]
    [ StatusBadgesArePrivate            = [String] {'', 'true', 'false'} ]
    [ DisableClassicPipelineCreation    = [String] {'', 'true', 'false'} ]
    [ DisableImpliedYAMLCiTrigger       = [String] {'', 'true', 'false'} ]
    [ Ensure                           = [String] {'Present', 'Absent'} ]
}
```

## Properties

### Common Properties

- **OrganizationName**: The name of the Azure DevOps organization. This property is mandatory and serves as the key property for the resource.
- **EnforceJobAuthScope**: Limit job authorization scope to the current project for non-release pipelines, organization-wide.
- **EnforceJobAuthScopeForReleases**: Limit job authorization scope to the current project for release pipelines, organization-wide.
- **EnforceReferencedRepoScopedToken**: Protect access to repositories in YAML pipelines, organization-wide.
- **EnforceSettableVar**: Limit variables that can be set at queue time, organization-wide.
- **PublishPipelineMetadata**: Publish metadata from pipelines, organization-wide.
- **StatusBadgesArePrivate**: Disable anonymous access to status badges, organization-wide.
- **DisableClassicPipelineCreation**: Disable creation of classic build and release pipelines, organization-wide.
- **DisableImpliedYAMLCiTrigger**: Disable implied YAML CI triggers, organization-wide.
- **Ensure**: Specifies the desired state. These settings are intrinsic to the organization and cannot be removed, so `Absent` is a no-op.

Each setting is a tri-state string: `'true'`, `'false'`, or `''` (the default). Only settings set to `'true'` or `'false'` are reconciled; a setting left as `''` is **not managed** by this resource and is left untouched.

## Additional Information

This resource manages the organization-scoped pipeline general settings
(`_apis/build/generalsettings` with no project segment — Organization Settings → Pipelines →
Settings). It shares the same eight tri-state switches as the project-scoped
[`AzDoPipelineSettings`](AzDoPipelineSettings.md), and the two resources share their
comparison and PATCH logic.

**Organization lock:** a switch forced *on* here is enforced for every project in the
organization. `AzDoPipelineSettings` detects this: when it finds a locked switch, it excludes
that property from its own drift comparison, reports it in a `LockedProperties` result field,
emits a warning, and never attempts to `PATCH` it — even if the project's own configuration
asks for it to be off. Set the switch off here, at the organization, to unlock it for
projects.

Three organization-only switches described in issue #83 — disabling classic release pipeline
creation, disabling marketplace tasks, and disabling built-in/in-box tasks — are not yet
implemented. Their exact `generalsettings` JSON keys have not been confirmed against a live
organization; see `docs/ResourceRoadmap.md` for the plan to add them once confirmed.

## Examples

## Example 1: Sample Configuration using AzDoOrgPipelineSettings Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    Node localhost {
        AzDoOrgPipelineSettings HardenOrgPipelines {
            Ensure                           = 'Present'
            OrganizationName                 = 'MyOrganization'
            EnforceJobAuthScope              = 'true'
            EnforceReferencedRepoScopedToken = 'true'
            StatusBadgesArePrivate           = 'true'
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoOrgPipelineSettings
$properties = @{
    OrganizationName    = 'MyOrganization'
    EnforceJobAuthScope = 'true'
}

Invoke-DscResource -Name 'AzDoOrgPipelineSettings' -Method Get -Property $properties -ModuleName 'AzureDevOpsDscNative'
```

## Example 3: Sample Configuration using Dsc.PipelineRunner

``` YAML
parameters: {}

variables: {
  OrganizationName: MyOrganization
}

resources:
- name: Harden organization pipeline settings
  type: AzureDevOpsDscNative/AzDoOrgPipelineSettings
  properties:
    OrganizationName: $OrganizationName
    EnforceJobAuthScope: 'true'
    EnforceReferencedRepoScopedToken: 'true'
    StatusBadgesArePrivate: 'true'
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
