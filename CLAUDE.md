# AzureDevOpsDsc — LLM Context File

PowerShell DSC module providing class-based DSC resources for managing Azure DevOps objects (projects, repos, permissions, pipelines, etc.) via the Azure DevOps REST API.

---

## Repository Layout

```
C:\Git\AzureDevOpsDsc\
├── source\
│   ├── Classes\                          # DSC resource classes (numbered 001–092)
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
| `004.DscResourceBase.ps1` | `DscResourceBase` | Root base class |
| `006.AzDevOpsDscResourceBase.ps1` | `AzDevOpsDscResourceBase` | All resources inherit this |
| `020.AzDoProject.ps1` | `AzDoProject` | Projects |
| `042.AzDoAreaPermission.ps1` | `AzDoAreaPermission` | CSS Security Namespace |
| `043.AzDoIterationPermission.ps1` | `AzDoIterationPermission` | CSS Security Namespace |
| `069.AzDoPipelinePermission.ps1` | `AzDoPipelinePermission` | CSS Security Namespace |
| `092.AzDoCheckConfiguration.ps1` | `AzDoCheckConfiguration` | Approval checks on environments |

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

# Expected: 1611 Passed, 0 Failed, 10 Skipped (as of branch fix/tests-and-code)
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
`C:\Users\<user>\Documents\PowerShell\Modules\AzureDevOpsDsc\0.0.2\`

After editing source files, always rebuild and redeploy before running integration tests — integration tests exercise the **deployed** module, not the source files.

---

## Enum Reference

| File | Enum | Values |
|------|------|--------|
| `DSCGetSummaryState.ps1` | `DSCGetSummaryState` | `Changed=0`, `Unchanged=1`, `NotFound=2`, `Error=3` |
| `Ensure.ps1` | `Ensure` | `Present`, `Absent` |
| `TokenType.ps1` | `TokenType` | `ManagedIdentity=0`, `PersonalAccessToken=1` |
| `RequiredAction.ps1` | `RequiredAction` | `None`, `New`, `Set`, `Remove`, `NoChange` |
| `DescriptorType.ps1` | `DescriptorType` | Various ACL descriptor types |

---

## Branch

Active development branch: `fix/tests-and-code`

The commit `a7b538d` on this branch resolved all unit test failures and most integration test failures (53 files changed, 569 insertions, 255 deletions). Key fixes included:
- `AzDoAreaPermission`: fixed null AreaPath early-return and token construction
- `AzDoGroupPermission`, `AzDoOrganizationSettings`, `AzDoCheckConfiguration`, `AzDoWiki`: replaced `Invoke-AzDevOpsApiRestMethod` calls with `New-RestAuthHeader` + `Invoke-RestMethod` and switched org-name source from global to clixml read
