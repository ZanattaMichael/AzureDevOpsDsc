---
name: run-azuredevopsdscnative
description: Run, build, and test the AzureDevOpsDscNative PowerShell DSC module. Use whenever the user wants to run tests, run Pester, run the unit tests, run the Common suite, build the module, verify changes to source/, smoke-test a resource, or otherwise drive the module locally. Also for questions like "does this test still pass?" or "does the module still load?".
---

# run-azuredevopsdscnative

This repo produces one PowerShell module: **AzureDevOpsDscNative** (name from
`source/AzureDevOpsDscNative.psd1`). It has no runnable app — it's a library
loaded by DSC. The interesting things to "run" here are the **unit test
suites** and the **build**.

**Paths in this document are relative to the repo root** (`/home/user/AzureDevOpsDsc`).
The driver itself lives at `.claude/skills/run-azuredevopsdscnative/driver.sh`.

---

## What this container can and cannot do

| Task | Runs here? | Why |
|---|---|---|
| **Common unit suite** (`azuredevopsdsc.common.tests.ps1`) | Yes — via driver | Dot-sources source files. No build needed. ~60s on this container. |
| **Load-only smoke** (`-LoadModulesOnly`) | Yes — via driver | Confirms every helper/cache/public file parses. |
| **Classes unit suite** (`azuredevopsdsc.tests.ps1`) | **No** | Test files parse-time resolve types via `using module AzureDevOpsDscNative` against the built module. No build = no run. |
| **Build** (`./build.ps1 -Tasks build`) | **No** | Needs Sampler/ModuleBuilder/InvokeBuild from PowerShell Gallery; PSGallery is proxy-blocked here (`www.powershellgallery.com` -> 403). CI runs the build on `windows-latest`. |
| **Integration tests** | **No** | Hit a live Azure DevOps org. Only run on the self-hosted `AZDO-AGENT` runner from `.github/workflows/integration-tests.yml`. See CLAUDE.md. |

The driver picks the largest suite that actually works headless on Linux. If
you need the Classes suite or a full build verify, push and let CI run it.

---

## Prerequisites

Handled automatically by the driver on first run:

- **PowerShell 7** (installs `powershell` from
  `https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb`
  — the 22.04 package works on 24.04).
- **Pester 5.7.1** side-loaded to `/root/psmods/Pester/5.7.1/` from
  `https://api.nuget.org/v3-flatcontainer/pester/5.7.1/pester.5.7.1.nupkg`.
  The nupkg is a Chocolatey package: the module ships under `tools/`,
  the driver copies it to `<root>/Pester/5.7.1/`.

You never need to run `Install-Module` — it would fail against PSGallery.

---

## Run

### Full Common suite (default — the one to use)

```bash
.claude/skills/run-azuredevopsdscnative/driver.sh
```

Expected on this container: `Passed: 1672  Failed: 31  Skipped: 10  Duration: ~00:01:00`.

The 31 failures are Linux-only and cluster on:
- **Cache export/import** (`Export-CacheObject`, `Import-CacheObject`,
  `Initialize-CacheObject`, `BypassFileCheck switch`) — path-separator and
  clixml round-trip differences vs Windows.
- **`New-AzDoAuthenticationProvider` parameter sets** and **`Token export
  functionality`** — DPAPI SecureString APIs are Windows-only.
- **`Get-AzDoProjectPermission` / `AzDoPipelinePermission`** — a test-fixture
  security-namespace lookup that only resolves against Windows-shipped data.

On the `windows-latest` CI runner these all pass. Don't treat the local
number as a regression signal; treat a delta against 1672/31/10 as one.

### One file or one subtree

```bash
# Single file
.claude/skills/run-azuredevopsdscnative/driver.sh \
  ./tests/Unit/Modules/AzureDevOpsDsc.Common/Api/Functions/Private/Cache/Get-CacheItem.tests.ps1

# Whole subtree (e.g. all Cache tests, all AzDoProject tests)
.claude/skills/run-azuredevopsdscnative/driver.sh \
  ./tests/Unit/Modules/AzureDevOpsDsc.Common/Api/Functions/Private/Cache
```

### Load-only smoke (fast: dot-sources source, no tests)

```bash
.claude/skills/run-azuredevopsdscnative/driver.sh --load-only
```

Use this when editing a private helper or a public resource function and you
just want to know it parses.

---

## Build

**Do not attempt** — PSGallery is proxy-blocked in this container.

The way it's done on CI (`.github/workflows/unit-tests.yml`, on
`windows-latest`):

```pwsh
./build.ps1 -ResolveDependency -Tasks build
```

Output lands in `output/builtModule/AzureDevOpsDscNative/<version>/`. That
directory is what the Classes suite adds to `PSModulePath` before running
Pester.

If the build task is what you actually need to test, push to a branch and
let `Unit Tests` workflow run it.

---

## Integration tests

Never runnable here. Live Azure DevOps org + self-hosted runner. Doc lives
in `CLAUDE.md` and `tests/Integration/Invoke-Tests.ps1`. To run them, push
a tag (only the user is authorised to tag) and the release pipeline
executes `integration-tests.yml`.

---

## Gotchas

- **Backslashes in test paths are the norm.** The bootstrap scripts use
  `$Global:RepositoryRoot\source\...` — that string is fed to `Import-Module`
  / `Get-ChildItem` on Linux and PowerShell resolves it correctly because
  those cmdlets are separator-tolerant. Don't "fix" the backslashes.
- **`$Global:RepositoryRoot` is required.** Both bootstrap files (and every
  test that uses `Get-FunctionItem` / `Find-MockedFunctions`) key off this
  global. The driver always runs the bootstrap first (`-LoadModulesOnly`),
  which sets it. Running a stray `Invoke-Pester ./tests/...` from a bare
  pwsh will fail with "term 'Get-FunctionItem' is not recognized" — that's
  the tell.
- **PSGallery is blocked; nuget.org is not.** For every module you'd
  normally `Install-Module` from PSGallery, check first whether it exists
  on `api.nuget.org` — Pester does, most of the Sampler stack does not.
- **`Get-Variable Azdo*` in `Refresh-AzDoCache`.** When you run tests that
  hit `Refresh-AzDoCache`, all globals matching `Azdo*` in the current
  session get wiped. It's expected — don't chase "my variable disappeared".
- **Docs task and the `.METHOD` help keyword.** If unit tests suddenly
  break with "Cannot index into a null array" during `GetHelpContent`, a
  class file has grown an invalid `.METHOD` in its help block. Fold the
  methods into `.NOTES` (see the fix in PR #41, files 042 and 043).
- **DPAPI-encrypted SecureStrings in `ModuleSettings.clixml`.** Any test
  that decrypts a fixture SecureString by round-tripping through clixml
  will fail on Linux — DPAPI is Windows-only. That's why the token-export
  suite is in the 31 expected failures.

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| `pwsh: command not found` | Re-run the driver — it installs `powershell` on first run. If that also fails, apt is offline; wait for the outbound proxy to recover. |
| `Unable to find repository 'PSGallery'` | You tried to `Install-Module`. Use the driver's nupkg-from-nuget.org side-load path instead. |
| `The term 'Get-FunctionItem' is not recognized` | You bypassed the bootstrap. Always run `azuredevopsdsc.common.tests.ps1 -LoadModulesOnly` (the driver does this for you) before calling `Invoke-Pester` on the Common suite. |
| `Unable to find type [AzDevOpsApiDscResourceBase]` on the Classes suite | You tried to run the Classes suite without a built module. Not fixable here — needs `./build.ps1 -Tasks build` on a machine with PSGallery access. Push and let CI run it. |
| Driver hangs installing pwsh | The proxy has a `403` on the Microsoft package repo. Retry once; the transient case is common right after container start. |
| Test count deltas from `1672 / 31 / 10` | The Common suite has changed. Compare the failing test-file list (rerun with `--load-only` then a targeted subtree) against the "cluster" list above to see if it's a new Linux-only flake or a real regression. |
