# DSC AzDoPipelineAuthorization Resource

## Syntax

```PowerShell
AzDoPipelineAuthorization [string] #ResourceName
{
    ProjectName           = [String]$ProjectName
    ResourceType          = [String] {'endpoint', 'queue', 'variablegroup', 'securefile', 'environment', 'repository'}
    ResourceName          = [String]$ResourceName
    [ AuthorizedPipelines = [String[]]$AuthorizedPipelines ]
    [ AllPipelines        = [Boolean]$AllPipelines ]
    [ ExclusiveList       = [Boolean]$ExclusiveList ]
    [ Ensure              = [String] {'Present', 'Absent'} ]
}
```

## Properties

### Common Properties

- **ProjectName**: The name of the Azure DevOps project. This property is mandatory and serves as the key property for the resource.
- **ResourceType**: The type of protected resource. Valid values are `endpoint` (service connection), `queue` (agent queue), `variablegroup`, `securefile`, `environment`, and `repository`. This property is mandatory.
- **ResourceName**: The name of the resource (or, for `repository`, the name of the Git repository). This property is mandatory.
- **AuthorizedPipelines**: The pipeline definitions (by name or folder path) allowed to use the resource. Additive by default — see `ExclusiveList`.
- **AllPipelines**: Whether every pipeline in the project may use the resource without individual authorization (the portal's "Open access" toggle). Defaults to `$false`.
- **ExclusiveList**: When `$true`, a pipeline authorized on the resource in Azure DevOps but absent from `AuthorizedPipelines` is revoked. When `$false` (the default), `AuthorizedPipelines` only adds authorizations and never removes one it did not itself grant.
- **Ensure**: Specifies whether the state should exist. See **Ensure = Absent** below.

## Additional Information

This resource manages the `pipelinePermissions` REST API — the "Pipeline permissions" tab shown
against a service connection, agent queue, variable group, secure file, environment or repository
in the Azure DevOps portal. It controls which pipeline *definitions* may consume the resource at
run time.

### Distinct from the security-namespace permission resources

This is not the same thing as `AzDoServiceConnectionPermission`, `AzDoVariableGroupPermission`,
`AzDoSecureFilePermission` or `AzDoEnvironmentPermission`. Those resources use ACLs to control who
may *administer* the resource (edit it, delete it, manage its permissions). This resource controls
which pipelines may *use* it while running. A user can have full administrative rights over a
variable group and still need it explicitly authorized before a pipeline they did not personally
approve can read it.

### Distinct from AzDoCheckConfiguration

`AzDoCheckConfiguration` attaches a check (for example an approval) that gates a *run* against a
protected resource. This resource decides whether a pipeline can reach the resource at all, before
any check is evaluated.

### Repository resourceId is a composite

For `ResourceType = 'repository'`, Azure DevOps addresses the pipeline permission record by
`{projectId}.{repositoryId}` rather than by the repository's own id alone. This resource resolves
both ids from `ProjectName`/`ResourceName` and builds that composite id automatically.

### There is nothing to create or delete

Like `AzDoPipelineSettings`, pipeline authorization is a setting on a resource that already exists
rather than an object with its own lifecycle — there is no separate "authorization object" to
create or remove. `Ensure = 'Absent'` is treated conservatively: only the pipelines this
configuration itself listed in `AuthorizedPipelines` are revoked, and `AllPipelines` is reset to
`$false` (the secure default), regardless of `ExclusiveList`. A pipeline authorized in the portal
that this configuration never declared is left untouched.

## Examples

## Example 1: Sample Configuration using AzDoPipelineAuthorization Resource

``` PowerShell
Configuration ExampleConfig {
    Import-DscResource -ModuleName 'AzureDevOpsDscNative'

    Node localhost {
        AzDoPipelineAuthorization ReleaseVariableGroup {
            Ensure              = 'Present'
            ProjectName         = 'MyProject'
            ResourceType        = 'variablegroup'
            ResourceName        = 'Release Secrets'
            AuthorizedPipelines = @('Deploy-Production')
            AllPipelines        = $false
            ExclusiveList       = $true
        }
    }
}

Start-DscConfiguration -Path ./ExampleConfig -Wait -Verbose
```

## Example 2: Sample Configuration using Invoke-DSCResource

``` PowerShell
# Return the current configuration for AzDoPipelineAuthorization
$properties = @{
    ProjectName  = 'MyProject'
    ResourceType = 'variablegroup'
    ResourceName = 'Release Secrets'
}

Invoke-DscResource -Name 'AzDoPipelineAuthorization' -Method Get -Property $properties -ModuleName 'AzureDevOpsDscNative'
```

## Example 3: Sample Configuration using Dsc.PipelineRunner

``` YAML
parameters: {}

variables: {
  ProjectName: MyProject
}

resources:
- name: Release Secrets Authorization
  type: AzureDevOpsDscNative/AzDoPipelineAuthorization
  dependsOn:
    - AzureDevOpsDscNative/AzDoVariableGroup/Release Secrets
  properties:
    ProjectName: $ProjectName
    ResourceType: variablegroup
    ResourceName: Release Secrets
    AuthorizedPipelines:
      - Deploy-Production
    AllPipelines: false
    ExclusiveList: true
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
