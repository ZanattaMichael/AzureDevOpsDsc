# Usage Documentation

This document covers the module's settings and the features that cut across resources:
environment variables, logging, export, secret references and running at scale. For a first run,
start with the [README](README.md#quick-start).

Related guides, published to the [wiki](https://github.com/ZanattaMichael/AzureDevOpsDsc/wiki):

| Guide | What it covers |
|---|---|
| [Authentication](https://github.com/ZanattaMichael/AzureDevOpsDsc/wiki/Authentication) | Every sign-in method and the setup each needs. |
| [Upgrading to 2.0](https://github.com/ZanattaMichael/AzureDevOpsDsc/wiki/Upgrading-to-2.0) | Moving from 1.x. |
| [Using the module with DSC v3](https://github.com/ZanattaMichael/AzureDevOpsDsc/wiki/DscV3) | The `dsc` command-line tool and configuration documents. |
| [Caching](https://github.com/ZanattaMichael/AzureDevOpsDsc/wiki/Caching) | What is cached, when it changes and how to reset it. |
| [Troubleshooting](https://github.com/ZanattaMichael/AzureDevOpsDsc/wiki/Troubleshooting) | Error messages and what to do about them. |

## Prerequisites

- **PowerShell 7.0 or later.**
- **The module**, from the PowerShell Gallery:

    ```powershell
    Install-PSResource -Name AzureDevOpsDscNative
    ```

- **To use `Invoke-DscResource`:** the `PSDesiredStateConfiguration` module, version 2.
  PowerShell 7.2 and later no longer include it.

    ```powershell
    Install-PSResource -Name PSDesiredStateConfiguration -Version '[2.0.5,3.0.0)'
    ```

- **To use DSC v3:** the `dsc` command-line tool with its PowerShell adapter. See
  [Using the module with DSC v3](https://github.com/ZanattaMichael/AzureDevOpsDsc/wiki/DscV3).
- **To use secret references to a vault:** `Microsoft.PowerShell.SecretManagement` and a
  registered vault.

Nothing else is needed to use the module. The modules needed to build and test it are listed in
[CONTRIBUTING.md](CONTRIBUTING.md).

## Environment Variables

| Variable | Required | Purpose |
|---|---|---|
| `AZDODSC_CACHE_DIRECTORY` | Yes | Folder for the stored credential and the cache. |
| `AZDODSC_ALLOW_SHARED_CACHE_DIRECTORY` | No | `1` turns the Linux and macOS check that the cache folder is private into a warning. |
| `AZDODSC_ALLOWED_API_HOSTS` | No | Extra hosts the credential may be sent to. |
| `AZDODSC_REQUEST_TIMEOUT_SECONDS` | No | Request timeout. Default 300. |
| `AZDODSC_MAX_RESPONSE_PAGES` | No | Most pages read for one listing. Default 10000. |
| `AZDO_VERBOSELOGGING_FILEPATH`, `AZDO_WARNINGLOGGING_FILEPATH`, `AZDO_ERRORLOGGING_FILEPATH` | No | Files that receive verbose, warning and error messages. |

Set them for every process that runs the module (a service, a scheduled task, a pipeline job, the
`dsc` command), not only for an interactive session.

### *AZDODSC_CACHE_DIRECTORY* Environment Variable

The system environment variable `AZDODSC_CACHE_DIRECTORY` is used by the module
to store caching settings and the cache itself. Make sure this variable is properly
set up in your system environment.

Treat the directory as credential storage. `New-AzDoAuthenticationProvider` writes
`ModuleSettings.clixml` there, which holds the personal access token (or client
secret / certificate password) and the current access token. On Windows those values
are DPAPI-encrypted for the account that wrote them; on Linux and macOS there is no
DPAPI and they are stored in a recoverable form, protected only by file permissions.
The module sets owner-only permissions on the directory and on every file it writes
there, and warns on non-Windows. Keep the directory on a private, local path (never
a shared or world-readable one), and run DSC as the same account that ran
`New-AzDoAuthenticationProvider`. The `Cache` subfolder is security-relevant too: it
maps identity names to descriptors, so anything that can write it can redirect a
permission grant.

The cache holds no secrets: secret variable values, service connection keys and audit
stream keys are removed before a value is cached. On Windows each cache file is also
encrypted with DPAPI for the account that wrote it, so, like `ModuleSettings.clixml`,
it can only be read by that account on that machine and cannot be opened with
`Import-Clixml`. A cache directory copied to another machine or account has to be
rebuilt by running `New-AzDoAuthenticationProvider` there. On Linux and macOS the
cache files are plain CLIXML protected by the owner-only permissions. Cache files
written by an earlier version are still read, and are encrypted the next time they
are written.

### *AZDODSC_ALLOW_SHARED_CACHE_DIRECTORY* Environment Variable

On Linux and macOS a resource only reads the stored credential when the cache directory is owned
by the current account (or root) and has no group or other permissions. Otherwise the run stops
and names the fix (`chmod 700`). Sign-in also fails, without writing the credential, if it cannot
restrict the directory's permissions.

Where the permissions cannot be changed, such as a volume mounted into a container, set
`AZDODSC_ALLOW_SHARED_CACHE_DIRECTORY` to `1` to get a warning instead of the failure. Only do
this when nothing else can write to the directory. The check is not made on Windows.

### *AZDODSC_REQUEST_TIMEOUT_SECONDS* and *AZDODSC_MAX_RESPONSE_PAGES* Environment Variables

Every request to Azure DevOps has a timeout of 300 seconds, so a server that accepts a connection
and then says nothing cannot hold a run open. Set `AZDODSC_REQUEST_TIMEOUT_SECONDS` to a whole
number of seconds to change it.

A listing that spans several pages stops with an error after 10000 pages, or when a response
repeats the continuation token of the previous page. Set `AZDODSC_MAX_RESPONSE_PAGES` to raise the
limit for a very large organization.

### *AZDODSC_ALLOWED_API_HOSTS* Environment Variable

The module only sends its credential to Azure DevOps Services hosts: `dev.azure.com`,
its service hosts (`vssps.`, `vsrm.`, `vsaex.`, `feeds.`, `auditservice.`,
`extmgmt.dev.azure.com` and so on) and the legacy `<organization>.visualstudio.com`
hosts. An authenticated request to any other host is refused before the
`Authorization` header is built, with the error
`Refusing to send the Azure DevOps credential to '<host>'`. Nothing needs to be
configured for Azure DevOps Services.

`AZDODSC_ALLOWED_API_HOSTS` adds hosts to that list. It is a comma separated list of
host names (no scheme, port or path), each matched exactly, with no wildcards:

```powershell
$env:AZDODSC_ALLOWED_API_HOSTS = 'tfs.contoso.com'
```

It exists for Azure DevOps Server (on-premises) collections, which the module does
not support (see `docs/AzureDevOpsServerSupport.md`). Every host named here
receives the credential, so only name hosts you operate.

### *AZDO_VERBOSELOGGING_FILEPATH*, *AZDO_WARNINGLOGGING_FILEPATH* and *AZDO_ERRORLOGGING_FILEPATH* Environment Variables

The `AZDO_VERBOSELOGGING_FILEPATH`, `AZDO_WARNINGLOGGING_FILEPATH` and
`AZDO_ERRORLOGGING_FILEPATH` environment variables are typically used in Azure
DevOps (AzDO) pipelines or custom scripts to specify file paths where verbose,
warning and error logs should be stored.
These variables help manage logging by directing different types of log messages
to separate files, aiding in better organization and analysis.

#### Usage

- **AZDO_WARNINGLOGGING_FILEPATH**: This variable defines the path to a file
where all warnings generated during the execution of a pipeline or script will
be logged. It's useful for tracking non-critical issues that may need attention
but do not halt the execution.

- **AZDO_ERRORLOGGING_FILEPATH**: This variable specifies the path to a file
designated for logging errors. Errors are typically more severe than warnings
and might require immediate action or investigation.

- **AZDO_VERBOSELOGGING_FILEPATH**: This variable specifies the path to a file
that receives every verbose message. It is detailed and slows the module down, so
set it only while troubleshooting.

#### Secrets in logs and error messages

Before a message reaches the verbose, warning or error stream, or one of these log
files, anything shaped like a credential is replaced with `<redacted>`: `Basic` and
`Bearer` header values, JSON Web Tokens (every Entra ID access token is one), Azure
DevOps personal access tokens, and `name=value` pairs whose name says it is a secret
(`client_secret`, `password`, `access_token`, `serviceprincipalkey` and similar). The
same applies to error messages built from an API response, an identity provider
error or Azure CLI output, and a quoted response body is cut off at 4,000
characters.

Redaction works on shape, so a secret with no recognisable shape, such as a short
custom API key logged without a label, is not caught. Treat the log files as
sensitive anyway: they name projects, identities and URIs. The module creates each
log file with owner-only permissions (the same as the cache directory); a file that
already exists keeps the permissions it has.

## Authentication

Before any resource runs, sign in once with `New-AzDoAuthenticationProvider`, as the account that
will run DSC. It stores the credential in `AZDODSC_CACHE_DIRECTORY` and builds the cache.

```powershell
# Managed identity
New-AzDoAuthenticationProvider -OrganizationName 'contoso' -useManagedIdentity

# Personal access token, as a SecureString
$pat = Read-Host -Prompt 'Personal access token' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'contoso' -SecureStringPersonalAccessToken $pat
```

A personal access token and a client secret are only accepted as a `SecureString`. The plain-text
`-PersonalAccessToken` and `-ClientSecret` parameters were removed in 2.0.

`-OrganizationName` is the organization's name only, not its URL: for
`https://dev.azure.com/contoso` pass `contoso`. A value that is not 1 to 50 letters,
digits or hyphens, starting and ending with a letter or digit, is refused before any
token is requested. `-TenantId`, where an authentication type takes one, must be the
tenant GUID or a verified domain name such as `contoso.onmicrosoft.com`.

The [Authentication guide](https://github.com/ZanattaMichael/AzureDevOpsDsc/wiki/Authentication) covers all six sign-in methods (personal access
token, managed identity, service principal with a client secret or a certificate, Azure CLI and
workload identity federation), and what each needs set up in Azure DevOps and Microsoft Entra ID.

## Sample Invocation

1. Set the cache directory and sign in:

    ```powershell
    $env:AZDODSC_CACHE_DIRECTORY = Join-Path $HOME '.azuredevopsdsc'
    New-AzDoAuthenticationProvider -OrganizationName 'contoso' -useManagedIdentity
    ```

1. Define the properties of the resource:

    ```powershell
    $properties = @{
        ProjectName = 'Contoso'
        GroupName   = 'Release Approvers'
    }
    ```

1. Check, then apply:

    ```powershell
    Invoke-DscResource -Name 'AzDoProjectGroup' -ModuleName 'AzureDevOpsDscNative' -Method Test -Property $properties
    Invoke-DscResource -Name 'AzDoProjectGroup' -ModuleName 'AzureDevOpsDscNative' -Method Set -Property $properties
    ```

With DSC v3 the same resource is `AzureDevOpsDscNative/AzDoProjectGroup`:

```powershell
dsc resource set --resource AzureDevOpsDscNative/AzDoProjectGroup --input '{"ProjectName":"Contoso","GroupName":"Release Approvers"}'
```

## Onboarding an Existing Organization with Export

Rather than hand-writing a DSC configuration for objects that already exist in an
organization, resources that support export can generate one from the live state.

### How Export is dispatched

DSC v3's PowerShell adapter (`Microsoft.Adapter/PowerShell`, `adapters/powershell/psDscAdapter/psDscAdapter.psm1`
in [PowerShell/DSC](https://github.com/PowerShell/DSC)) discovers a class-based resource's
export support by reflecting over its methods: `GetExportMethod` looks for a method literally
named `Export`, and invokes the parameterless overload it finds with
`$method.Invoke($null, $null)`. There is no filtered/parameterized `Export($instance)` overload
in this module — every exporter returns everything the API will let it see, unfiltered, exactly
as the adapter's own dispatch expects.

The manifest capability this requires is not something to add by hand: `New-DscAdaptedResourceManifest`
(from `DscResource.Authoring`, run by `build.ps1 -Tasks dscv3`) derives a resource's `capabilities`
list — `get`, `set`, `test`, `delete`, `export`, `whatif`, `sethandlesexist` — from which of the
matching methods the class actually defines. Adding a class's own `static [<Class>[]] Export()`
method is therefore enough; `.build/tasks/2.Fix_DscAdaptedResourceManifestTypes.ps1` only patches
JSON-schema property *types* in the generated manifest and never touches the capabilities list, so
no manifest-generation code needs to change.

### Which resources support export

| Resource | Exported properties | Notes |
|---|---|---|
| `AzDoProject` | `Ensure`, `ProjectName`, `ProjectDescription`, `Visibility` | `SourceControlType` and `ProcessTemplate` are never emitted — they cannot be changed by `Set-AzDoProject` after creation, so including them would report drift `Test()` can never resolve. Projects in `deleting`/`deleted`/`createPending` state are skipped. |
| `AzDoGitRepository` | `Ensure`, `ProjectName`, `RepositoryName` | `SourceRepository` (fork-from-template) is never emitted for the same reason. Disabled repositories are skipped. |

Every other resource is out of scope for this increment; see `docs/ResourceRoadmap.md` for the
plan of record. Calling `Export()` on a resource that has no `Export-<ResourceName>` function
throws `"export is not implemented for <ResourceName>"` rather than silently returning nothing.

### Running an export

From a session with the module imported and authenticated (see **Authentication** above):

```powershell
using module AzureDevOpsDscNative

$exportedProjects = [AzDoProject]::Export()
$exportedRepositories = [AzDoGitRepository]::Export()
```

Each call returns an array of resource instances whose properties are already in the exact form
`Get-<ResourceName>` reports them, so feeding one straight back through `Test()` reports
`InDesiredState = $true` with no further editing:

```powershell
$properties = @{
    ProjectName        = $exportedProjects[0].ProjectName
    ProjectDescription = $exportedProjects[0].ProjectDescription
    Visibility          = $exportedProjects[0].Visibility.ToString()
}

Invoke-DscResource -Name 'AzDoProject' -Method Test -Property $properties -ModuleName 'AzureDevOpsDscNative'
```

### Secrets in exported output

If a resource declares any of its properties secret (via a `GetDscResourceSecretPropertyNames()`
override), export never writes the real value out. Each secret property is replaced with the fixed
placeholder `<REDACTED-BY-EXPORT>`, and a warning names the resource and property so the omission is
visible rather than silently wrong. `AzDoProject` and `AzDoGitRepository` declare no secret
properties today; the placeholder mechanism (`Protect-AzDoExportedSecretProperty`) is shared by
every exporter and is exercised with a synthetic resource in
`tests/Unit/Modules/AzureDevOpsDsc.Common/Api/Functions/Private/Helper/Protect-AzDoExportedSecretProperty.tests.ps1`.
Replace the placeholder with the real value by hand before applying an exported configuration that
contains one.

## Keeping Secrets out of a Configuration

A configuration document is a file: it is committed, copied, and compiled into a MOF. A secret
written into it as a literal travels with it. Wherever one of these resources takes a secret,
give a *reference* instead, and the module fetches the secret on the machine applying the
configuration:

| Reference | Where the secret comes from |
|-----------|-----------------------------|
| `@{ SecretEnvironmentVariable = 'NAME' }` | The environment variable `NAME` of the process running DSC. |
| `@{ SecretName = 'Name' }` | `Microsoft.PowerShell.SecretManagement`, default vault. |
| `@{ SecretName = 'Name'; SecretVault = 'Vault' }` | `Microsoft.PowerShell.SecretManagement`, named vault. |

References are accepted in:

- `AzDoVariableGroup` — as a variable: `Variables = @{ API_KEY = @{ SecretEnvironmentVariable = 'API_KEY' } }`.
  The variable is stored as a secret.
- `AzDoServiceConnection` — as any value in `Authorization`, including under `parameters`.
- `AzDoServiceHook` and `AzDoAuditStream` — as any value in `ConsumerInputs`.
- `AzDoPipeline` — as the `Value` of a variable. Set `IsSecret = $true` on it as well.

```powershell
AzDoVariableGroup 'Deployment' {
    ProjectName       = 'Contoso'
    VariableGroupName = 'Deployment'
    Variables         = @{
        Region  = 'australiaeast'
        API_KEY = @{ SecretEnvironmentVariable = 'DEPLOYMENT_API_KEY' }
        DB_PWD  = @{ SecretName = 'DeploymentDbPassword'; SecretVault = 'Production' }
    }
}
```

A reference that cannot be resolved (variable not set, secret not found, SecretManagement not
installed) fails the resource rather than storing an empty secret. The secret is needed for
`Test` and `Get` as well as `Set`, so it has to be available to every DSC run. A literal value
still works. Every resolved secret is redacted from the module's verbose, warning and error output.

## Implementation using `Dsc.PipelineRunner`

[Current Source](https://github.com/ZanattaMichael/Dsc.PipelineRunner/)

This module integrates with `Dsc.PipelineRunner`, a platform-agnostic pipeline
runner built on Datum. By utilizing YAML resource files, similar to Ansible
playbooks, administrators can manage their environment using Configuration as
Code (CaC).

`Dsc.PipelineRunner` has no hard dependency on Azure DevOps: configuration
source, authentication, and the resource execution engine (DSC v2's
`Invoke-DscResource` or cross-platform DSC v3's `dsc.exe`) are all pluggable
**Actions**. Azure DevOps support is one opt-in `Connect` action among
several, resolved via `AzureDevOpsDsc.Common` and this module
(`AzureDevOpsDscNative`), and is not required to use the runner.

Import the module and invoke it with the provider-agnostic entry point:

```powershell
Import-Module Dsc.PipelineRunner

Invoke-DscRunner -Source Git -SourceContext @{ Url = $repoUrl } `
                 -Connect AzureDevOps -ConnectContext @{ OrganizationName = 'MyOrg'; AuthenticationType = 'ManagedIdentity' } `
                 -Engine DscV2 `
                 -Mode Set
```

`-Connect AzureDevOps` signs this module in for you with a managed identity (the default) or a
personal access token (`AuthenticationType = 'PAT'` and `PATToken` in the context). For any other
sign-in method, run `New-AzDoAuthenticationProvider` yourself first and leave `-Connect` out. Set
`AZDODSC_CACHE_DIRECTORY` before the run either way.

> **Personal access tokens and module 2.0.** At the time 2.0 was released, the runner passed the
> token to `New-AzDoAuthenticationProvider` with the plain-text `-PersonalAccessToken` parameter,
> which 2.0 removed. Until the runner is updated, use a managed identity through the runner, or
> sign in yourself and run `Invoke-DscRunner` without `-Connect AzureDevOps`.

Existing Azure DevOps pipelines can continue to use the `Invoke-DscPipelineRunner`
back-compat shim, which maps its Azure DevOps-flavored parameters onto
`Invoke-DscRunner -Source Git -Connect AzureDevOps`. It imports the `AzureDevOpsDsc.Common`
module by name, so that module (it ships inside this one, under `Modules`) has to be on
`PSModulePath`. Azure DevOps support is not a hard dependency of the core `Dsc.PipelineRunner`
module:

```powershell
Import-Module Dsc.PipelineRunner

$env:PIPELINERUNNER_CACHE_DIRECTORY = 'C:\Datum\Cache'

$params = @{
    AzureDevopsOrganizationName = 'MyOrg'
    ExportConfigDir             = 'C:\Datum\DSCOutput\'
    ConfigurationSourcePath     = 'https://configuration-path'
    JITToken                    = $env:SYSTEM_ACCESSTOKEN
    Mode                        = 'Set'
    ReportPath                  = 'C:\Datum\DSCOutput\Reports'
}

Invoke-DscPipelineRunner @params
```

`Invoke-DscPipelineRunner` no longer has an `-AuthenticationType` parameter: passing `-PATToken`
selects a personal access token, and leaving it out uses the managed identity. `-ExportConfigDir`
must already exist, and `-Mode` defaults to `Test`.

> New integrations should prefer `Invoke-DscRunner`. See the [Dsc.PipelineRunner
> README](https://github.com/ZanattaMichael/Dsc.PipelineRunner#public-commands)
> for the full parameter reference for both commands, and
> [Dsc.PipelineRunnerActions](https://github.com/ZanattaMichael/Dsc.PipelineRunnerActions) for
> ready-made pipeline steps for GitHub Actions, Azure Pipelines, GitLab, CircleCI and Jenkins.

The runner compiles Datum configuration into its own cache directory, set with `-CacheDirectory`
or `PIPELINERUNNER_CACHE_DIRECTORY` (the legacy `AZDODSC_CACHE_DIRECTORY` is still honoured as a
back-compat alias). `Invoke-DscRunner` falls back to a temporary directory when neither is set.
`Invoke-DscPipelineRunner` requires one of the variables.

Below is an example of how you can define parameters, variables, and resources in a YAML file to manage your Azure DevOps environment:

**FileName: ProjectPolicies\Project.yml**
```yaml
parameters: {}

variables: {
}

resources:

  - name: Project
    type: AzureDevOpsDscNative/AzDoProject
    properties:
      projectName: $ProjectName
      projectDescription: $ProjectDescription
      visibility: private
      SourceControlType: Git
      ProcessTemplate: Agile
```

**FileName: AllNodes\SampleProject\Project.yml**
```yaml
parameters: {}

variables:
  ProjectName: SampleProject
  ProjectDescription: 'Never gonna give you up, never gonna let you down!'

resources:
  - name: Project Services
    type: AzureDevOpsDscNative/AzDoProjectServices
    dependsOn:
      - AzureDevOpsDscNative/AzDoProject/Project
    properties:
      projectName: $ProjectName
      BuildPipelines: disabled
      AzureArtifact: disabled
```

### Explanation

- **Parameters**: This section is reserved for any input parameters that the configuration might require.
- **Variables**: Here, you can define reusable variables such as `ProjectName` and `ProjectDescription`.
- **Resources**: This section defines the actual resources to be managed. In this example, we have a resource named "Project Services" of type `AzureDevOpsDscNative/AzDoProjectServices`. 

#### Resource Properties

- `projectName`: Uses the variable `$ProjectName` defined earlier.
- `BuildPipelines`: Set to `disabled`.
- `AzureArtifact`: Set to `disabled`.

The `dependsOn` attribute ensures that the "Project Services" resource will only be configured after the `AzureDevOpsDscNative/AzDoProject/Project` resource has been set up.
