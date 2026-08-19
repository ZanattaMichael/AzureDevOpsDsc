# LCM Configuration (AZDO-DSC-LCM)

**AzureDevOpsDscNative** gives you the DSC *resources* (`AzDoProject`, `AzDoGitPermission`, etc.). To actually run those resources at scale — across many projects, with reusable policy, dependency ordering, and conditional logic — you use the companion project **[AZDO-DSC-LCM](https://github.com/ZanattaMichael/AzDO-DSC-LCM)**, a Local Configuration Manager (LCM) built on top of [Datum](https://github.com/gaelcolas/Datum) for configuration merging.

This page explains how the two projects fit together and how to structure a configuration. It is a summary of `AZDO-DSC-LCM`'s own README — for anything not covered here, refer to that repository directly, as it is the source of truth for the LCM.

## How it fits together

```
AZDO-DSC-LCM (this page)          AzureDevOpsDscNative (rest of this wiki)
─────────────────────────         ──────────────────────────────────────
Datum-merged YAML configs   ──►    DSC resources (AzDoProject, AzDoGitPermission, ...)
LCM Rules (validation)      ──►    applied against your Azure DevOps org
dependsOn / condition logic
```

Datum merges layered YAML configuration stubs (organization policy → project-area policy → per-project overrides) into one resolved configuration per project. The LCM then loads that resolved configuration, runs validation/formatting rules against it, orders resources by their `dependsOn` graph, and invokes each DSC resource in turn.

## Configuration directory layout

A `Datum.yml` at the root of your configuration repo defines the merge precedence and versioning. From the real example shipped in `AZDO-DSC-LCM`'s `Example Configuration/Datum.yml`:

```yaml
ResolutionPrecedence:
  - Projects\$($Node.ProjectPresence)\$($Node.Project)
  - ProjectPolicies\ProjectGitRepositories
  - ProjectPolicies\ProjectGroups
  - ProjectPolicies\Project
  - OrganizationPolicies\OrganizationGroups
  - OrganizationPolicies\Organization

DatumHandlersThrowOnError: true
default_lookup_options: MostSpecific

LCMConfigSettings:
  ConfigurationVersion: 0.1
  AZDOLCMVersion: 0.1
  DSCResourceVersion: 2.0

lookup_options:
  variables:
    merge_hash_array: deep
  resources:
    merge_hash_array: UniqueKeyValTuples
    merge_options:
      tuple_keys:
        - name
```

**Lower-level configuration wins on conflict.** Organization-wide policy sits at the top of the precedence list (highest/loosest level); per-project files sit at the bottom and override anything above them for that project.

The example repository's directory layout:

- `Example Configuration/OrganizationPolicies/` — org-wide settings (`Organization.yml`, `OrganizationGroups.yml`)
- `Example Configuration/ProjectPolicies/` — reusable policy applied to every project (`Project.yml`, `ProjectGroups.yml`, `ProjectGitRepositories.yml`)
- `Example Configuration/Projects/Present/` and `Example Configuration/Projects/Absent/` — one YAML file per project, keyed by its desired presence state (e.g. `Magenta.yml`, `Blue.yml`)

A real per-project resource block (from `Projects/Present/Magenta.yml`), showing how an `AzDoGitPermission` resource is declared with variables, a `dependsOn` chain, and an ACE list:

```yaml
- name: Configuration Git Permissions
  type: AzureDevOpsDsc/AzDoGitPermission
  dependsOn:
    - AzureDevOpsDsc/AzDoGitRepository/Configuration Git Repository
    - AzureDevOpsDsc/AzDoProjectGroup/CON Readers
    - AzureDevOpsDsc/AzDoProjectGroup/CON Board Administrators
  properties:
    ProjectName: $ProjectName
    RepositoryName: $ProjectRepositoryName
    isInherited: false
    Permissions:
      - Identity: '[$ProjectName]\$ProjectGroups_Role_CONReaders'
        Permission:
          Read: "Allow"
      - Identity: '[$ProjectName]\$ProjectGroups_Role_CONContributors'
        Permission:
          Read: "Allow"
          Contribute: "Allow"
          CreateBranch: "Allow"
          PullRequestContribute: "Allow"
```

Note the `type:` value is `AzureDevOpsDsc/<ResourceName>` and `name:` becomes part of the dependency-graph key referenced by other resources' `dependsOn` (`AzureDevOpsDsc/<ResourceName>/<name>`).

## LCM features available on every resource

- **`dependsOn`** — orders execution; a resource only runs after everything it depends on has completed.
- **`condition`** — a PowerShell expression evaluated before the resource runs; if it evaluates `$true` **the resource is skipped**. Example: `condition: $ProjectWorkBoardsStatus -eq 'enabled'`.
- **`postExecutionScript`** — a script block run after the resource executes (success or failure), e.g. to call `Stop-TaskProcessing` and halt the rest of the run.
- **Calculated properties** — any property value can be a PowerShell subexpression, e.g. `Ensure: $( if ([string]::IsNullOrEmpty($Project_Ensure)) { 'Present' } else { $Project_Ensure } )`.
- **Custom variables** — declared in a `variables:` block per file and referenced with `$VariableName` inside `properties:`.

## LCM Rules

Modular scripts under `LCM Rules/` in the `AZDO-DSC-LCM` repo validate and format the merged configuration before anything is applied:

- `LCM Rules/PreParse/Test-CircularReferences.ps1` — fails the run if `dependsOn` forms a cycle.
- `LCM Rules/PreParse/Test-ResourcesForIncorrectProperties.ps1` — validates resource properties against the documented spec for that resource type; errors block the run.
- `LCM Rules/Custom/Sort-DependsOn.ps1` — orders resources by their `dependsOn` graph. This one is mandatory and cannot be bypassed.
- `LCM Rules/Format/` — formatting rules (empty by default in the example repo; extend as needed).

These are plain PowerShell scripts, so you can add your own alongside them if your organization needs additional pre-flight checks.

## Running the LCM: `Invoke-AZDoLCM`

The entry point is the `Invoke-AZDoLCM` cmdlet, exported by the `azdo-dsc-lcm` module (`source/Public/Invoke-AZDoLCM.ps1`). Real parameters, taken from the cmdlet's source:

| Parameter | Required | Notes |
|---|---|---|
| `AzureDevopsOrganizationName` | Yes | Target Azure DevOps organization name |
| `exportConfigDir` | Yes | Existing directory where Datum writes its compiled configuration |
| `ConfigurationSourcePath` | Yes | A URL (cloned automatically) or a local directory path containing the Datum configuration |
| `JITToken` | Yes | Just-in-time access token |
| `Mode` | Yes | `'Test'` (default) or `'Set'` — `Test` validates without applying, `Set` applies |
| `AuthenticationType` | No | `'ManagedIdentity'` (default) or `'PAT'` |
| `PATToken` | Only if `AuthenticationType='PAT'` | Must be a 52-character alphanumeric PAT |
| `ReportPath` | No | Directory to write a report to |

```powershell
Invoke-AZDoLCM `
    -AzureDevopsOrganizationName 'MyOrg' `
    -exportConfigDir 'C:\Configs' `
    -ConfigurationSourcePath 'https://dev.azure.com/MyOrg/_git/MyLCMConfigRepo' `
    -JITToken $jitToken `
    -Mode 'Set' `
    -AuthenticationType 'ManagedIdentity'
```

Internally, `Invoke-AZDoLCM`:
1. Requires the `AZDODSC_CACHE_DIRECTORY` environment variable to be set (throws immediately if it isn't — see the [Authentication](Authentication) page for what lives in that directory).
2. Clones `ConfigurationSourcePath` if it's a URL, or uses it directly if it's a local directory.
3. Compiles the Datum configuration into `exportConfigDir` via `Build-DatumConfiguration`.
4. Establishes the Azure DevOps authentication provider (PAT or Managed Identity) via `New-AzDoAuthenticationProvider`.
5. Runs the LCM Rules and applies/tests the resulting resources in dependency order.

## Setting up a self-hosted agent to run the LCM

From `AZDO-DSC-LCM`'s own setup instructions:

1. Clone `AZDO-DSC-LCM` onto the agent (or a path it can reach), and lay out your Datum configuration directory following the precedence guidance above — put organization-wide policy at the top, project-specific overrides at the bottom, and keep per-project YAML changes minimal to avoid "snowflake" projects.
2. Store the configuration source in your normal source control, so it's versioned and auditable like any other infrastructure config.
3. Set up a self-hosted Azure DevOps agent ([Microsoft's agent docs](https://learn.microsoft.com/en-us/azure/devops/pipelines/agents/agents?view=azure-devops)) to run the LCM.
   - If using **Managed Identity via Azure Arc**, run the Agent Pool service under an administrator account, and add the Arc machine's identity to the **Project Collection Administrators** group (or grant it equivalent namespace-level permissions for whatever it needs to manage — see [Permissions & ACLs](Permissions)).
   - If using **Managed Identity on an Azure VM**, enable the VM's managed identity per [Microsoft's managed identity docs](https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/overview), then grant it Azure DevOps permissions the same way.
   - If using a **PAT**, create a service identity in Azure DevOps and generate its PAT for the pipeline to consume.
4. Install the modules listed under `RequiredModules` in `source/azdo-dsc-lcm.psd1` on the agent (`PSDesiredStateConfiguration`, `powershell-yaml`, `AzureDevOpsDsc.Common`, `AzureDevOpsDsc`, `datum`, plus anything else listed there for your version) with `Install-Module -Name <ModuleName>`, and confirm with `Get-Module -ListAvailable -Name <ModuleName>`.
5. Keep `LCMConfigSettings` in `Datum.yml` (`ConfigurationVersion`, `AZDOLCMVersion`, `DSCResourceVersion`) aligned with the module versions you have installed — the LCM rejects a configuration whose declared versions don't match.
6. Run with `Mode = 'Test'` first in your pipeline to validate the configuration compiles and applies cleanly without making changes, watch for runtime errors, then switch to `Mode = 'Set'` to apply for real.

## See also

- [Permissions & ACLs](Permissions) — the permission resources you'll most often see driven from LCM configuration, plus an `AzDO-DSC-LCM` YAML example for each
- [Authentication](Authentication) — how `AZDODSC_CACHE_DIRECTORY` / `ModuleSettings.clixml` and the LCM's own auth provider relate
- [AZDO-DSC-LCM repository](https://github.com/ZanattaMichael/AzDO-DSC-LCM) — source of truth for anything not covered here
