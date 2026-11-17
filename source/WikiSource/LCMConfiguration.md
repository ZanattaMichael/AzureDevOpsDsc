# Pipeline Runner Configuration (Dsc.PipelineRunner)

AzureDevOpsDscNative provides the DSC resources. To apply them across many projects, with shared
policy, ordering and conditions, use the companion project
**[Dsc.PipelineRunner](https://github.com/ZanattaMichael/Dsc.PipelineRunner)**. It merges layered
YAML configuration with [Datum](https://github.com/gaelcolas/Datum), orders the resources, and
runs each one through DSC v2 (`Invoke-DscResource`) or DSC v3 (`dsc`).

The runner is a separate project with its own releases, and it is not specific to Azure DevOps.
This page covers how the two fit together. For everything about the runner itself, its
[wiki](https://github.com/ZanattaMichael/Dsc.PipelineRunner/wiki) is the source of truth.

## Install

```powershell
Install-PSResource -Name Dsc.PipelineRunner
Install-PSResource -Name AzureDevOpsDscNative
```

Azure DevOps support is opt-in in the runner: it does not install this module for you. Install
both where the run happens.

## Connecting the runner to Azure DevOps

The runner signs in to Azure DevOps through its `AzureDevOps` connect action, which calls
`New-AzDoAuthenticationProvider` for you.

```powershell
Import-Module Dsc.PipelineRunner

Invoke-DscRunner -ConfigurationSourcePath 'C:\config' `
    -Connect AzureDevOps `
    -ConnectContext @{ OrganizationName = 'contoso'; AuthenticationType = 'ManagedIdentity' } `
    -Mode Test
```

| `ConnectContext` key | Meaning |
|---|---|
| `OrganizationName` | The organization name. Required. |
| `AuthenticationType` | `ManagedIdentity` (the default) or `PAT`. |
| `PATToken` | The personal access token, when `AuthenticationType` is `PAT`. |

`-Mode Test` reports drift and `-Mode Set` applies. `-Engine DscV2` (the default) uses
`Invoke-DscResource`, and `-Engine DscV3` drives `dsc`.

Set `AZDODSC_CACHE_DIRECTORY` before the run. The connect action signs this module in, and
sign-in needs that variable. See [Authentication](Authentication#before-you-sign-in).

> **Personal access tokens and module 2.0.** At the time 2.0 was released, the runner's
> `AzureDevOps` connect action and `Invoke-DscPipelineRunner` passed the token with the plain-text
> `-PersonalAccessToken` parameter, which 2.0 removed. Until the runner is updated, use managed
> identity through the runner, or sign in yourself with `New-AzDoAuthenticationProvider` and run
> `Invoke-DscRunner` without `-Connect AzureDevOps`. See [Upgrading to 2.0](Upgrading-to-2.0).

To use another sign-in method (service principal, certificate, workload identity federation),
sign in yourself first and run `Invoke-DscRunner` without `-Connect`:

```powershell
New-AzDoAuthenticationProvider -OrganizationName 'contoso' -TenantId $tenantId -ClientId $clientId -useGitHubActionsOIDC
Invoke-DscRunner -ConfigurationSourcePath './config' -Mode Set
```

### `Invoke-DscPipelineRunner`

`Invoke-DscPipelineRunner` is the runner's older, Azure DevOps-flavoured entry point, kept for
existing pipelines. New work should use `Invoke-DscRunner`.

```powershell
$env:PIPELINERUNNER_CACHE_DIRECTORY = 'C:\Datum\Cache'

Invoke-DscPipelineRunner `
    -AzureDevopsOrganizationName 'contoso' `
    -ExportConfigDir 'C:\Datum\DSCOutput' `
    -ConfigurationSourcePath 'https://dev.azure.com/contoso/Platform/_git/Configuration' `
    -JITToken $env:SYSTEM_ACCESSTOKEN `
    -Mode Test
```

Its parameters have changed. If you are updating an older pipeline:

- `-AuthenticationType` was removed. Passing `-PATToken` selects a personal access token, and
  leaving it out uses the managed identity.
- `-Mode` and `-JITToken` are optional. `-Mode` defaults to `Test`.
- `-ExportConfigDir` must be an existing directory.
- A cache directory variable must be set. `PIPELINERUNNER_CACHE_DIRECTORY` is preferred, and
  `AZDODSC_CACHE_DIRECTORY` is still accepted.

## Running from a pipeline

[Dsc.PipelineRunnerActions](https://github.com/ZanattaMichael/Dsc.PipelineRunnerActions) packages
the runner as a step for GitHub Actions, Azure Pipelines, GitLab, CircleCI and Jenkins, so you do
not have to script the install and the call. For a self-hosted Azure DevOps agent, including the
identity the agent runs as, see the runner's
[Azure DevOps agent guide](https://github.com/ZanattaMichael/Dsc.PipelineRunner/blob/main/docs/azure-devops-self-hosted-agent.md).

## Writing resources

A resource in a runner configuration names this module in its `type`:

```yaml
parameters: {}

variables:
  ProjectName: Contoso
  ProjectDescription: Managed by DSC

resources:

  - name: Project
    type: AzureDevOpsDscNative/AzDoProject
    properties:
      ProjectName: $ProjectName
      ProjectDescription: $ProjectDescription
      Visibility: Private
      SourceControlType: Git
      ProcessTemplate: Agile

  - name: Project Services
    type: AzureDevOpsDscNative/AzDoProjectServices
    dependsOn:
      - AzureDevOpsDscNative/AzDoProject/Project
    properties:
      ProjectName: $ProjectName
      BuildPipelines: disabled
```

- **`type`** is `AzureDevOpsDscNative/<ResourceName>`. Configurations written for the module's
  old name, `AzureDevOpsDsc/<ResourceName>`, need updating.
- **`name`** identifies the instance. Other resources refer to it in `dependsOn` as
  `AzureDevOpsDscNative/<ResourceName>/<name>`.
- **`properties`** are the resource's own properties, as listed on each resource page in this
  wiki. Every resource page has a runner example.

The runner adds its own keys to a resource. Its wiki documents each one:

| Key | Purpose |
|---|---|
| `dependsOn`, `notify` | Ordering between resources. |
| `preCondition` | Skips the resource when the expression is false. `condition` is a deprecated alias. |
| `postCondition` | Fails the resource when the expression is false after it ran. |
| `preExecutionScript`, `postExecutionScript` | PowerShell run around the resource. Off unless `AllowExecutionScripts: true` is set in `PipelineRunnerSettings`. |

See [Resource Properties](https://github.com/ZanattaMichael/Dsc.PipelineRunner/wiki/Resource-Properties)
and [Composite Resources](https://github.com/ZanattaMichael/Dsc.PipelineRunner/wiki/Composite-Resources).

## The configuration repository

A runner configuration is a directory with a `Datum.yml` at its root. `Datum.yml` sets the order
in which layers are merged and carries the `PipelineRunnerSettings` block: the configuration
version, the runner version it targets, and the engine.

```yaml
PipelineRunnerSettings:
  ConfigurationVersion: 0.5
  PipelineRunnerVersion: 1.1.0
  Engine: DscV2
```

Older configurations used a block named `LCMConfigSettings` with an `AZDOLCMVersion` key. The
runner now reads `PipelineRunnerSettings`.

The runner repository has a complete
[example configuration](https://github.com/ZanattaMichael/Dsc.PipelineRunner/tree/main/Example%20Configuration)
for Azure DevOps, with organization policy, project policy and per-project files. See also
[Configuration Repository Layout](https://github.com/ZanattaMichael/Dsc.PipelineRunner/wiki/Configuration-Repository-Layout),
[PipelineRunnerSettings](https://github.com/ZanattaMichael/Dsc.PipelineRunner/wiki/PipelineRunnerSettings)
and [Getting Started](https://github.com/ZanattaMichael/Dsc.PipelineRunner/wiki/Getting-Started).

## See also

- [Authentication](Authentication): signing this module in, and what the cache folder holds.
- [Permissions & ACLs](Permissions): the permission resources most often driven from a runner
  configuration.
- [Using the module with DSC v3](DscV3): what the runner's DSC v3 engine relies on.
