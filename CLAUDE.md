# AzureDevOpsDscNative — LLM Context File

PowerShell DSC module providing class-based DSC resources for managing Azure DevOps objects (projects, repos, permissions, pipelines, boards, process customization, etc.) via the Azure DevOps REST API.

The module is named **AzureDevOpsDscNative** (see `source/AzureDevOpsDscNative.psd1`). Older notes and paths referring to `AzureDevOpsDsc` predate the rename; the *inner* helper module is still `AzureDevOpsDsc.Common`.

---

## Repository Layout

```
C:\Git\AzureDevOpsDsc\
├── source\
│   ├── Classes\                          # DSC resource classes (numbered 001–141)
│   ├── Enum\                             # PowerShell enums used across the module
│   └── Modules\
│       └── AzureDevOpsDsc.Common\
│           ├── Api\Functions\Private\    # Private API helpers
│           │   ├── Authentication\       # Add-AuthenticationHTTPHeader, etc.
│           │   ├── Cache\                # Cache read/write helpers
│           │   ├── Command\
│           │   ├── Helper\               # General helper functions
│           │   └── Api\
│           └── Resources\Functions\Public\  # One folder per DSC resource
├── tests\
│   ├── Unit\
│   │   ├── Classes\                      # Class-level unit tests
│   │   └── Modules\AzureDevOpsDsc.Common\
│   │       └── Resources\Functions\Public\  # Unit tests mirroring source/Public
│   └── Integration\
│       ├── Resources\                    # One .tests.ps1 per DSC resource
│       ├── Supporting\                   # Test framework init, teardown, API helpers
│       │   ├── Functions\
│       │   ├── API\
│       │   ├── APICalls\
│       │   ├── Initalize-TestFramework.ps1
│       │   └── Teardown.ps1
│       ├── Invoke-Tests.ps1              # Official integration test runner
│       └── TestFrameworkConfiguration.json
├── azuredevopsdsc.tests.ps1              # Unit test bootstrap (-LoadModulesOnly flag)
├── build.ps1                             # ModuleBuilder/Sampler build entry point
└── output\                               # Build artefacts (deployed module)
```

---

## DSC Resource Classes

All DSC resources live in `source\Classes\` with numeric prefixes controlling load order. Key files:

| File | Class | Notes |
|------|-------|-------|
| `001.AuthenticationToken.ps1` | `AuthenticationToken` | Base token class |
| `002.PersonalAccessToken.ps1` | `PersonalAccessToken` | PAT; `.Get()` has call-stack guard |
| `003.ManagedIdentityToken.ps1` | `ManagedIdentityToken` | MI token |
| `003b`–`003e` | `ServicePrincipalToken`, `CertificateToken`, `AzureCliToken`, `WorkloadIdentityFederationToken` | The other auth types |
| `004.DscResourceBase.ps1` | `DscResourceBase` | Root base class |
| `006.AzDevOpsDscResourceBase.ps1` | `AzDevOpsDscResourceBase` | All resources inherit this |
| `020.AzDoProject.ps1` | `AzDoProject` | Projects |
| `042.AzDoAreaPermission.ps1` | `AzDoAreaPermission` | `CSS` namespace |
| `043.AzDoIterationPermission.ps1` | `AzDoIterationPermission` | `Iteration` namespace |
| `069.AzDoPipelinePermission.ps1` | `AzDoPipelinePermission` | `Build` namespace |
| `092.AzDoCheckConfiguration.ps1` | `AzDoCheckConfiguration` | Approval checks on environments |
| `101`–`103` | `AzDoQueryFolder`, `AzDoWorkItemQuery`, `AzDoQueryPermission` | Shared work item queries; `WorkItemQueryFolders` namespace |
| `104.AzDoWIPTagHygiene.ps1` | `AzDoWIPTagHygiene` | Detects/merges misaligned work item tags |
| `105`–`106` | `AzDoSecureFile`, `AzDoSecureFilePermission` | Secure files; `Library` namespace |
| `107`–`108` | `AzDoPipelineFolder`, `AzDoPipelineFolderPermission` | Pipeline folder tree; `Build` namespace (folder token form) |
| `109`–`110` | `AzDoGroupEntitlement`, `AzDoServicePrincipalEntitlement` | Licensing at scale |
| `111`–`116` | `AzDoPicklist`, `AzDoProcessWorkItemType`, `AzDoProcessField`, `AzDoProcessState`, `AzDoProcessRule`, `AzDoProcessBehavior` | Inherited-process customization |
| `138`–`141` | `AzDoTestVariable`, `AzDoTestConfiguration`, `AzDoTestPlan`, `AzDoTestSuite` | Test management (test plan REST API 7.1); no test-plan security namespace exists, so there is no `AzDoTestPlanPermission` |

There are currently **69** `[DscResource()]` classes (classes `117`–`137` add other, unrelated resources not covered by this table). `docs/ResourceRoadmap.md` is the plan of record for what is implemented and what is still outstanding.

The `Construct()` method (in `AzDevOpsDscResourceBase`) runs at `new()` time, reads `ModuleSettings.clixml`, and sets `$Global:DSCAZDO_AuthenticationToken` and `$Global:DSCAZDO_OrganizationName`.

Public resource functions are in `source\Modules\AzureDevOpsDsc.Common\Resources\Functions\Public\<ResourceName>\`.

---

## Key Globals and Clixml

| Name | Purpose |
|------|---------|
| `$Global:DSCAZDO_AuthenticationToken` | Live token object (PAT or MI); set by `Construct()` |
| `$Global:DSCAZDO_OrganizationName` | Azure DevOps org name; set by `Construct()` |
| `$ENV:AZDODSC_CACHE_DIRECTORY` | Path to the module's cache directory |
| `$ENV:AZDODSC_CACHE_DIRECTORY\ModuleSettings.clixml` | Persisted auth config (org name + DPAPI-encrypted token SecureString) |

`ModuleSettings.clixml` structure:
```powershell
@{
    OrganizationName = 'myorg'
    Token = @{
        tokenType    = 'PersonalAccessToken'  # or 'ManagedIdentity' (may be int 0/1 after deserialization)
        access_token = [SecureString]          # DPAPI-encrypted on Windows
        expires_on   = [datetime]              # MI only
        expires_in   = [int]                   # MI only
    }
}
```

---

## Important Gotchas

### 1. Token `.Get()` call-stack guard
`PersonalAccessToken.Get()` and `ManagedIdentityToken.Get()` inspect the PowerShell call stack and throw if called from outside these three allowed callers:
- `Add-AuthenticationHTTPHeader`
- `Invoke-AzDevOpsApiRestMethod`
- `New-AzDoAuthenticationProvider`

**Never call `$Global:DSCAZDO_AuthenticationToken.Get()` directly from test code.**

### 2. DSC runspace isolation
`Invoke-DscResource` executes DSC methods in an isolated runspace. Variables set inside that runspace (including `$Global:DSCAZDO_AuthenticationToken`) do **not** propagate back to the calling test scope. After `Invoke-DscResource` returns, the global token is typically null.

### 3. `Add-AuthenticationHTTPHeader` not available in test scope
`azuredevopsdsc.tests.ps1 -LoadModulesOnly` dot-sources `Helper\` and `Cache\` subdirectories but **not** `Authentication\`. Calling `Add-AuthenticationHTTPHeader` or `Invoke-AzDevOpsApiRestMethod` from integration tests will fail with "not recognized."

### 4. DPAPI SecureString deserialization
`ModuleSettings.clixml` SecureStrings are DPAPI-encrypted. They are safely decryptable on the same machine and user account using `[System.Runtime.InteropServices.Marshal]`.

### 5. CSS Security Namespace performance
`AzDoAreaPermission`, `AzDoIterationPermission`, and `AzDoPipelinePermission` scan all org-level ACLs. Each test for these resources takes 200–400 seconds.

### 6. ACL tokens are built and parsed by separate functions
A security token passes through three functions, and they have to agree:
`New-ACLToken` parses a resource-side token name into a structured token, `ConvertTo-FormattedToken`
builds the API token string from it, and `Parse-ACLToken` reads what the API returns back into the
same structure. If the build and parse directions disagree, a permission written by `Set()` never
matches the ACL read by `Get()` and the resource reports drift forever. Add a round-trip test
whenever a namespace is added.

Namespace patterns live in `LocalizedData/000.LocalizedDataAzACLTokenPatten.ps1` (API-side token
shapes) and `001.LocalizedDataAzResourceTokenPatten.ps1` (resource-side names). They are *not*
interchangeable: the API addresses objects by id, the resource side by name.

### 7. PowerShell unrolls a single-element array on return
A function returning a one-element array hands the caller the bare element, so `.Count` on a lone
hashtable result gives its **key count**, not `1`. No cast avoids this. The convention here is that
the function returns naturally and callers wrap the call in `@()` — `@(Get-AzDoTagMisalignment ...)`.
Returning `,@($results)` to dodge it makes every element an array instead, which is worse.

### 8. Only inherited processes can be customized
The system processes (Agile, Scrum, Basic, CMMI) are read-only. `Resolve-AzDoProcessWorkItemType`
enforces this for every process customization resource, and has to read the `work/processes` view
to do it: the `LiveProcesses` cache is built from the classic `_apis/process/processes` endpoint,
which does not return `customizationType` or `parentProcessTypeId`.

### 9. Compare normalized, store what the user wrote
Several APIs return a reformatted version of what they were given — WIQL is re-indented and
re-cased, rule conditions come back as objects with omitted keys filled in as nulls, and paths are
written several ways. Comparing raw reports drift on every `Test()`. Each case has a pure
normalizer (`ConvertTo-NormalizedWiql`, `ConvertTo-NormalizedRuleClause`, `Format-AzDoQueryPath`,
`Format-AzDoPipelineFolderPath`) used **only for comparison** — what gets written back is always
what the configuration supplied.

---

## Auth Helper Pattern for Integration Tests

When an integration test needs to call the Azure DevOps REST API directly (not via `Invoke-DscResource`), use this pattern — do **not** call `Invoke-AzDevOpsApiRestMethod` or `Add-AuthenticationHTTPHeader`:

```powershell
function New-RestAuthHeader {
    $cfg  = Import-Clixml -Path (Join-Path $ENV:AZDODSC_CACHE_DIRECTORY 'ModuleSettings.clixml')
    $tok  = $cfg.Token
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($tok.access_token)
    try   { $plain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr) }
    finally { [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
    if ($tok.tokenType.ToString() -eq 'PersonalAccessToken' -or $tok.tokenType.ToString() -eq '1') {
        $encoded = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$plain"))
        return @{ Authorization = "Basic $encoded" }
    } else {
        return @{ Authorization = "Bearer $plain" }
    }
}

# Read org name the same way — globals may not be set when BeforeAll runs:
$settings = Import-Clixml -Path (Join-Path $ENV:AZDODSC_CACHE_DIRECTORY 'ModuleSettings.clixml')
$ORG      = $settings.OrganizationName
```

Place `New-RestAuthHeader` and the `$ORG` initialisation inside the `BeforeAll` block of each Describe that needs direct API access.

---

## Running Unit Tests

```powershell
# From repo root — runs all class unit tests
.\azuredevopsdsc.tests.ps1

# Run module-level unit tests (mirrors source\Modules\...)
$config = New-PesterConfiguration
$config.Run.Path = '.\tests\Unit\Modules'
$config.Output.Verbosity = 'Detailed'
Invoke-Pester -Configuration $config

# Current baseline (Windows CI): 2015 Passed, 0 Failed, 10 Skipped.
# On Linux 31 of those fail for environment reasons - see 'Testing Locally on Linux'.
```

---

## Running Integration Tests

Integration tests hit a live Azure DevOps organization and **must run as Administrator** because the deployed module path requires elevated access.

### Option A — Official runner (recommended)

```powershell
# Must be run from the tests\Integration directory
Set-Location 'C:\Git\AzureDevOpsDsc\tests\Integration'
.\Invoke-Tests.ps1 -TestFrameworkConfigurationPath '.\TestFrameworkConfiguration.json'
```

`Invoke-Tests.ps1`:
1. Dot-sources `Supporting\Functions`, `Supporting\API`, `Supporting\APICalls`
2. Calls `Supporting\Initalize-TestFramework.ps1` (loads and authenticates the module)
3. Runs pre-run teardown (cleans up stale resources from previous runs)
4. Runs Pester against `Resources\`
5. Writes XML results to `C:\Temp\integration-test-results.xml`
6. Runs post-run teardown

`TestFrameworkConfiguration.json` fields: `Organization`, `AuthenticationType` (`PAT` or `ManagedIdentity`), `PATToken` (PAT only), `excludedProjectsFromTeardown`.

### Option B — Direct Pester (skip framework init)

```powershell
# Only valid if the module is already deployed and the global token is already set
$config = New-PesterConfiguration
$config.Run.Path = 'C:\Git\AzureDevOpsDsc\tests\Integration\Resources'
$config.Output.Verbosity = 'Detailed'
Invoke-Pester -Configuration $config
```

---

## Build and Deploy

```powershell
# Build the module (uses ModuleBuilder/Sampler)
.\build.ps1 -Tasks build

# Redeploy to the local PowerShell modules directory after a build
.\scripts\redeploy-module.ps1
```

The deployed module lands at:
`<MyDocuments>\PowerShell\Modules\AzureDevOpsDscNative\<version>\`

`scripts\redeploy-module.ps1` resolves the version from `output\builtModule\AzureDevOpsDscNative\` rather than assuming one.

After editing source files, always rebuild and redeploy before running integration tests — integration tests exercise the **deployed** module, not the source files.

---

## Enum Reference

| File | Enum | Values |
|------|------|--------|
| `DSCGetSummaryState.ps1` | `DSCGetSummaryState` | `Changed=0`, `Unchanged=1`, `NotFound=2`, `Renamed=3`, `Missing=4`, `Error=5` |
| `Ensure.ps1` | `Ensure` | `Present`, `Absent` |
| `TokenType.ps1` | `TokenType` | `ManagedIdentity`, `PersonalAccessToken`, `Certificate`, `ServicePrincipal`, `AzureCLI`, `WorkloadIdentityFederation` |
| `RequiredAction.ps1` | `RequiredAction` | `None`, `Get`, `New`, `Set`, `Remove`, `Test`, `Error` |
| `DescriptorType.ps1` | `DescriptorType` | Various ACL descriptor types |

### How `Get` status maps to the action taken

`AzDevOpsDscResourceBase.GetDscRequiredAction()` turns the `status` a `Get-AzDo*` function returns into the function that runs next. Worth knowing before choosing a status:

| `Get` returns `status` | With `Ensure = Present` |
|---|---|
| `NotFound` | `New-AzDo*` |
| `Changed` / `Renamed` | `Set-AzDo*` |
| `Missing` | `Remove-AzDo*` |
| `Unchanged` | nothing |
| `Error` | **`Set-AzDo*`** — an error state does *not* stop the pipeline |

That last row matters: returning `Error` from `Get` still calls `Set`. Any refusal a `Get` decides on has to be repeated in `Set` (usually by checking `$LookupResult.reason`), or it will not hold. `Set-AzDoWIPTagHygiene` and `Set-AzDoPicklist` both do this.

---

## Resource Conventions

Each resource is four public functions in
`source\Modules\AzureDevOpsDsc.Common\Resources\Functions\Public\<ResourceName>\`, named
`Get-`, `New-`, `Set-` and `Remove-<ResourceName>`. The base class resolves them by that naming
convention, so a missing one fails at apply time rather than at author time.

`Get-` returns a hashtable carrying at least `Ensure`, `status` and `propertiesChanged`. Anything
else it puts there is handed to `New`/`Set`/`Remove` as `$LookupResult`, which is the normal way to
avoid a second lookup — resolved ids, ACL tokens and reference names are all passed this way.

A few conventions that are easy to get wrong:

- **`Force` is reserved.** `GetDesiredStateParameters()` injects `Force = $true` into every
  `New`/`Set` parameter set, so a DSC property named `Force` is always true by the time the
  function sees it. A guard property needs another name — `AllowRecursiveDelete`,
  `AllowDestructiveRemove`.
- **Exactly one `[DscProperty(Key)]`.** More than one throws at runtime. Other identifying
  properties are `[DscProperty(Mandatory)]`.
- **Only compare what the configuration states.** Use `$PSBoundParameters.ContainsKey(...)` rather
  than testing for an empty value, so an unspecified property is not read as "must be empty" and
  does not blank something set in the UI.

---

## Testing Locally on Linux

`.claude/skills/run-azuredevopsdscnative/` drives the suites headless. It installs PowerShell 7 and
side-loads Pester from nuget.org (PSGallery is proxy-blocked):

```bash
.claude/skills/run-azuredevopsdscnative/driver.sh              # full Common suite
.claude/skills/run-azuredevopsdscnative/driver.sh --load-only  # parse/smoke check only
.claude/skills/run-azuredevopsdscnative/driver.sh <path>       # one file or subtree
```

**Baseline: 31 failures is correct on Linux.** They are environment-specific — DPAPI SecureStrings,
cache clixml round-trips and Windows-only namespace fixtures — and all pass on the `windows-latest`
CI runner. Treat a *delta* from 31 as a regression, not the number itself.

The Classes suite (`azuredevopsdsc.tests.ps1`) and `build.ps1` cannot run in that container: the
first resolves types via `using module` against the built module, and the second needs Sampler and
ModuleBuilder from PSGallery. Push and let CI run them.

If `apt-get update` fails on unrelated third-party PPAs, disable the offending files under
`/etc/apt/sources.list.d/` and retry — the driver's PowerShell install needs a clean `apt update`.

---

## Branch

Active development branch: `resource-add/affectionate-tesla-citwbm`

The `resource-add/` prefix is load-bearing: `integration-tests.yml` runs the live-organization
suite on pull requests from branches with that prefix. Any other prefix leaves the suite
dispatch-only.

Recent work added 16 resources (classes `101`–`116`) covering work item queries, tag hygiene,
secure files, pipeline folders, entitlements and inherited-process customization, plus ACL token
support for the `WorkItemQueryFolders` namespace, the `SecureFile` form of `Library` and the folder
form of `Build`. See `CHANGELOG.md` for the detail and `docs/ResourceRoadmap.md` for what is left.
