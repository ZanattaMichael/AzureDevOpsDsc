# Usage Documentation

This document provides detailed instructions on how to use the module effectively.

## Prerequisites

Ensure you have the following prerequisites before proceeding:

- **PowerShell 7.0**
- **Required Modules**:
  - `ChangelogManagement`
  - `Configuration`
  - `DscResource.AnalyzerRules`
  - `DscResource.Common`
  - `DscResource.DocGenerator`
  - `DscResource.Test`
  - `InvokeBuild`
  - `MarkdownLinkCheck`
  - `Metadata`
  - `ModuleBuilder`
  - `Pester`
  - `Plaster`
  - `PSDepend`
  - `PSDscResources`
  - `PSScriptAnalyzer`
  - `Sampler`
  - `xDSCResourceDesigner`

__Using Install-Module__

``` PowerShell
# Run as Administrator
Install-Module -Scope AllUsers -Name @(
  'ChangelogManagement'
  'Configuration'
  'DscResource.AnalyzerRules'
  'DscResource.Common'
  'DscResource.DocGenerator'
  'DscResource.Test'
  'InvokeBuild'
  'MarkdownLinkCheck'
  'Metadata'
  'ModuleBuilder'
  'Pester'
  'Plaster'
  'PSDepend'
  'PSDscResources'
  'PSScriptAnalyzer'
  'Sampler'
  'xDSCResourceDesigner'
)
```

__Using Install-PSResource__

``` PowerShell
# Run as Administrator
Install-PSResource @(
  'ChangelogManagement'
  'Configuration'
  'DscResource.AnalyzerRules'
  'DscResource.Common'
  'DscResource.DocGenerator'
  'DscResource.Test'
  'InvokeBuild'
  'MarkdownLinkCheck'
  'Metadata'
  'ModuleBuilder'
  'Pester'
  'Plaster'
  'PSDepend'
  'PSDscResources'
  'PSScriptAnalyzer'
  'Sampler'
  'xDSCResourceDesigner'
)
```

### *AZDODSC_CACHE_DIRECTORY* Environment Variable

The system environment variable `AZDODSC_CACHE_DIRECTORY` is used by the module
to store caching settings and the cache itself. Make sure this variable is properly
set up in your system environment.

### *AZDO_WARNINGLOGGING_FILEPATH* and *AZDO_ERRORLOGGING_FILEPATH* Environment Variables

The `AZDO_WARNINGLOGGING_FILEPATH` and `AZDO_ERRORLOGGING_FILEPATH`environment
variables are typically used in Azure DevOps (AzDO) pipelines or custom scripts
to specify file paths where warning and error logs should be stored.
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

## Setting Up Managed Identity

Please use the following [documentation](https://learn.microsoft.com/en-us/azure/devops/integrate/get-started/authentication/service-principal-managed-identity?view=azure-devops) as a guide to create a managed identity in Azure DevOps.

## Authentication

Prior to accessing any resources, it is necessary to configure authentication by utilizing the `New-AzDoAuthenticationProvider` cmdlet.

```powershell
New-AzDoAuthenticationProvider -OrganizationName $AzureDevopsOrganizationName -UseManagedIdentity
```

## Sample Invocation

Here is an example of how to invoke a resource using the module:

1. Import the necessary modules:

    ```powershell
    Import-Module "\AzureDevOpsDscNative\0.0.1\Modules\DscResource.Common\0.17.1\DscResource.Common.psd1"
    Import-Module "\AzureDevOpsDscNative\0.0.1\Modules\AzureDevOpsDsc.Common\AzureDevOpsDsc.Common.psd1"
    Import-Module "\AzureDevOpsDscNative\0.0.1\AzureDevOpsDscNative.psd1"
    ```

1. Create a Managed Identity Token:

    ```powershell
    New-AzDoAuthenticationProvider -OrganizationName "akkodistestorg" -UseManagedIdentity
    ```

1. Define the properties to be used by the module:

    ```powershell
    $properties = @{
      ProjectName = 'UpdateSharePoint'
      GroupName = 'TESTGROUP5'
    }
    ```

1. Invoke the DSC Resource:

    ```powershell
    Invoke-DscResource -Name 'AzDoProjectGroup' -Method Set -Property $properties -ModuleName 'AzureDevOpsDscNative'
    ```

By following these steps, you can successfully set up and use the module with Azure DevOps.

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

Existing Azure DevOps pipelines can continue to use the `Invoke-DscPipelineRunner`
back-compat shim, which maps its Azure DevOps-flavored parameters onto
`Invoke-DscRunner -Source Git -Connect AzureDevOps` with no functional change
for existing callers. It requires the `AzureDevOpsDsc.Common` module to be
installed separately, since Azure DevOps support is no longer a hard
dependency of the core `Dsc.PipelineRunner` module:

```powershell
Import-Module Dsc.PipelineRunner

$params = @{
    AzureDevopsOrganizationName = 'MyOrg'
    exportConfigDir             = 'C:\Datum\DSCOutput\'
    ConfigurationSourcePath     = 'https://configuration-path'
    JITToken                    = $env:SYSTEM_ACCESSTOKEN
    Mode                        = 'Set'
    AuthenticationType          = 'ManagedIdentity'
    ReportPath                  = 'C:\Datum\DSCOutput\Reports'
}

Invoke-DscPipelineRunner @params
```

> New integrations should prefer `Invoke-DscRunner`. See the [Dsc.PipelineRunner
> README](https://github.com/ZanattaMichael/Dsc.PipelineRunner#public-commands)
> for the full parameter reference for both commands.

The cache directory used to compile Datum configuration is set via
`PIPELINERUNNER_CACHE_DIRECTORY` (the legacy `AZDODSC_CACHE_DIRECTORY` is
still honoured as a back-compat alias). `Invoke-DscRunner` doesn't require
either — pass `-CacheDirectory` explicitly, set one of those environment
variables, or let it fall back to a temporary directory.

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
