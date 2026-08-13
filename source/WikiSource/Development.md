# Development

This page covers loading the module from source, running the test suites, and
contributing to the project.

---

## Prerequisites

- **PowerShell 7.0+** (`pwsh`)
- **Git**
- **Windows** for integration tests (DSC engine is Windows-only; unit tests run
  cross-platform)

Clone the repository:

```powershell
git clone https://github.com/ZanattaMichael/AzureDevOpsDsc.git
cd AzureDevOpsDsc
```

---

## Loading from source — `Invoke-DevLoad.ps1`

`Invoke-DevLoad.ps1` bootstraps the module directly from source without a full
build. It dot-sources all enums, classes, and function files in dependency order,
sets `$env:AZDODSC_CACHE_DIRECTORY`, and runs 24 smoke checks.

```powershell
# Load the module for interactive use
. ./Invoke-DevLoad.ps1

# Load and run the Classes unit test suite
. ./Invoke-DevLoad.ps1 -RunClassTests

# Load and run the AzureDevOpsDsc.Common unit test suite
. ./Invoke-DevLoad.ps1 -RunCommonTests

# Load and run both suites
. ./Invoke-DevLoad.ps1 -RunAllTests

# Custom cache directory
. ./Invoke-DevLoad.ps1 -CacheDirectory C:\Temp\myCache
```

After loading, all public functions and DSC resource classes are available in
the current session. Authenticate and call resources interactively:

```powershell
New-AzDoAuthenticationProvider -OrganizationName 'myorg' -PersonalAccessToken '<pat>'
Invoke-DscResource -Name AzDoProject -Method Get -ModuleName AzureDevOpsDsc -Property @{ ProjectName = 'Test' }
```

---

## Building the module

The build uses [Sampler](https://github.com/gaelcolas/Sampler) /
[ModuleBuilder](https://github.com/PoshCode/ModuleBuilder).

```powershell
# Install build dependencies (first time only)
.\build.ps1 -Tasks noop -ResolveDependency

# Build the module
.\build.ps1 -Tasks build
```

The compiled module is written to `output/AzureDevOpsDsc/<version>/`.

---

## Running unit tests

The unit tests use [Pester 5](https://pester.dev/) and require no external
dependencies.

**Quick run via dev loader:**

```powershell
. ./Invoke-DevLoad.ps1 -RunAllTests
```

**Manual run:**

```powershell
Install-Module Pester -MinimumVersion 5.0 -Force -SkipPublisherCheck -Scope CurrentUser
Import-Module Pester -MinimumVersion 5.0 -Force

# Class-level tests
./azuredevopsdsc.tests.ps1

# AzureDevOpsDsc.Common module tests
./azuredevopsdsc.common.tests.ps1

# Or target a specific path
$config = New-PesterConfiguration
$config.Run.Path = './tests/Unit/Modules'
$config.Output.Verbosity = 'Detailed'
Invoke-Pester -Configuration $config
```

Expected baseline: **1611 Passed, 0 Failed, 10 Skipped**.

---

## Running integration tests

Integration tests hit a live Azure DevOps organization and create/delete real
resources. They must run as Administrator on Windows.

> **Warning** — always use a **dedicated test organization**. Tests tear down
> all resources they create, but failures can leave partial state.

```powershell
# Set the cache directory
$env:AZDODSC_CACHE_DIRECTORY = 'C:\Temp\AzDoCache'
New-Item -Path $env:AZDODSC_CACHE_DIRECTORY -ItemType Directory -Force | Out-Null

# Configure authentication
New-AzDoAuthenticationProvider -OrganizationName 'myorg' -PersonalAccessToken '<pat>'

# Run from the Integration directory
Set-Location tests/Integration
.\Invoke-Tests.ps1 -TestFrameworkConfigurationPath .\TestFrameworkConfiguration.json
```

`TestFrameworkConfiguration.json` fields:

| Field | Required | Description |
|---|---|---|
| `Organization` | Yes | Azure DevOps organization name |
| `AuthenticationType` | Yes | `PAT` or `ManagedIdentity` |
| `PATToken` | When PAT | Personal Access Token value |
| `excludedProjectsFromTeardown` | No | Projects to preserve during teardown |

**Run a targeted subset:**

```powershell
.\Invoke-TargetedTests.ps1 `
    -TestFrameworkConfigurationPath .\TestFrameworkConfiguration.json `
    -TestFile    AzDoArtifactFeed `
    -FullName    '*Creating*'
```

---

## Repository structure

```
AzureDevOpsDsc/
├── source/
│   ├── Classes/          # DSC resource classes (001–092, load-ordered)
│   ├── Enum/             # PowerShell enums
│   └── Modules/
│       └── AzureDevOpsDsc.Common/
│           ├── Api/Functions/Private/
│           │   ├── Authentication/   # Auth helpers + token updaters
│           │   ├── Cache/
│           │   ├── Helper/
│           │   └── Api/
│           └── Resources/Functions/Public/   # One folder per DSC resource
├── tests/
│   ├── Unit/             # Fast, no external dependencies
│   └── Integration/      # Requires live Azure DevOps org
├── Invoke-DevLoad.ps1    # Dev loader (load from source without build)
└── build.ps1             # Sampler/ModuleBuilder entry point
```

---

## Contributing

1. Fork the repository and create a feature branch.
2. Run `.\build.ps1 -Tasks noop -ResolveDependency` to install dev tools.
3. Make your changes.
4. Run `./azuredevopsdsc.tests.ps1` and `./azuredevopsdsc.common.tests.ps1` to
   ensure all unit tests still pass.
5. Open a pull request — the CI workflows run automatically.

See [CONTRIBUTING.md](https://github.com/ZanattaMichael/AzureDevOpsDsc/blob/main/CONTRIBUTING.md)
for the full guidelines.
