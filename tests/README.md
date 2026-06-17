# Unit and integration tests for AzureDevOpsDsc

This module is tested with [Pester 5](https://pester.dev/). Tests are split into two
suites:

| Suite | Location | Dependencies |
|-------|----------|--------------|
| **Unit** | [`tests/Unit`](Unit) | None — mock everything, fast to run. |
| **Integration** | [`tests/Integration`](Integration) | A live Azure DevOps organization and authentication. |

## Test tags

Every `Describe` block is tagged so suites and services can be selected from the
command line. Each block carries a **type** tag and a **service** tag, and some unit
tests keep an additional **category** tag.

| Tag kind | Values | Meaning |
|----------|--------|---------|
| Type | `Unit`, `Integration` | Which suite the test belongs to. |
| Service | e.g. `ArtifactFeed`, `Project`, `GitPermission`, `CheckConfiguration` | The resource/service under test. Shared by a service's unit and integration tests. |
| Category | `API`, `Cache`, `ACL`, `Helper`, `Authentication` | Sub-area of the private module (unit tests only). |

The **service tag is normalised across the suites** so a single tag runs both the
unit and the integration tests for a service. For example, the private API function
tests under `Api/ArtifactFeed`, the resource tests under
`Resources/.../AzDoArtifactFeed`, and the integration test
`Resources/AzDoArtifactFeed.tests.ps1` all share the `ArtifactFeed` service tag.

### Examples

```powershell
Invoke-Pester -Tag Unit                 # every unit test
Invoke-Pester -Tag Integration          # every integration test
Invoke-Pester -Tag ArtifactFeed         # unit + integration tests for ArtifactFeed
Invoke-Pester -Tag Unit, API            # unit tests for the private API functions
Invoke-Pester -Tag Unit, Cache          # unit tests for the cache helpers
```

## Running the unit tests

Build the module first so the compiled module and class types are available, then
run Pester against `tests/Unit`:

```powershell
./build.ps1 -Tasks build
Invoke-Pester -Path ./tests/Unit -Tag Unit
```

## Running the integration tests

> **Warning:** integration tests create and delete real resources in the target
> Azure DevOps organization. Only run them against a dedicated test organization.

Integration tests run through a small framework that performs authentication,
pre-run teardown, test execution and post-run teardown. Configure the target
organization in `TestFrameworkConfiguration.json`, set the cache directory, then run:

```powershell
$env:AZDODSC_CACHE_DIRECTORY = '<path-to-a-writable-cache-folder>'

Set-Location ./tests/Integration
. ./Invoke-Tests.ps1 -TestFrameworkConfigurationPath ./TestFrameworkConfiguration.json
```

### Running a subset (targeted runner)

[`Invoke-TargetedTests.ps1`](Integration/Invoke-TargetedTests.ps1) runs a subset of
the integration suite — useful while iterating on a single resource — and reuses the
same framework setup/teardown.

```powershell
. ./Invoke-TargetedTests.ps1 `
    -TestFrameworkConfigurationPath ./TestFrameworkConfiguration.json `
    -TestFile AzDoArtifactFeed, AzDoProjectPermission `   # one or more files (prefix-glob)
    -FullName '*Creating*' `                              # optional Context/It name filter
    -SkipTeardown                                         # optional: skip the slow teardown
```

| Parameter | Purpose |
|-----------|---------|
| `-TestFile` | Limit discovery to specific resource test files (bare name, file name, or path; prefix-globbed). |
| `-FullName` | Wildcard filter on the full `Describe > Context > It` name, so a single `Context` can run in isolation. |
| `-SkipTeardown` | Skip the pre/post-run teardown (only when the target resources are already clean). |

See [`CONTRIBUTING.md`](../CONTRIBUTING.md) for the integration test framework design
and setup details.
