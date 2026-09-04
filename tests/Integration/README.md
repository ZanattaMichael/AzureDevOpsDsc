# Integration Tests

These tests exercise DSC resources against a **real** Azure DevOps organization - they create,
modify, and tear down actual resources. Only run them against a disposable/test organization.

There are two suites, and they are independent:

| Suite | Path | Host | Runner |
|---|---|---|---|
| DSC v2 | `Resources/` | `Invoke-DscResource` | `Invoke-Tests.ps1` |
| DSC v3 | `V3/` | the `dsc` CLI, through `Microsoft.Adapter/PowerShell` | `V3/Invoke-V3Tests.ps1` |

Both drive the same resources, so a failure in one and not the other points at the host rather
than at the resource. They share the `TestFrameworkConfiguration.json` schema below, and in CI
they are separate workflows sharing one self-hosted runner - see **Running in CI**.

## Configuration

`TestFrameworkConfiguration.json` (tracked, with placeholder values) documents the expected shape:

```json
{
    "Organization" : "your-org-name-here",
    "AuthenticationType" : "ManagedIdentity",
    "excludedProjectsFromTeardown": [
        "DSC Pipeline Services"
    ]
}
```

To run against your own organization, copy it to `TestFrameworkConfiguration.local.json` (already
covered by `.gitignore`'s `*.local.*` pattern - it will never be committed) and fill in your real
values there:

```powershell
Copy-Item .\TestFrameworkConfiguration.json .\TestFrameworkConfiguration.local.json
# edit TestFrameworkConfiguration.local.json with your real Organization
```

Then point the runner at your local file instead of the tracked template:

```powershell
.\Invoke-Tests.ps1 -TestFrameworkConfigurationPath '.\TestFrameworkConfiguration.local.json'
```

`AuthenticationType` supports `ManagedIdentity` or `PAT` (see `Supporting\Initalize-TestFramework.ps1`
for how each is wired up). Running elevated (Administrator) is required if you're authenticating via
Managed Identity on an Azure Arc-connected machine - see the Managed Identity authentication code
under `source/Modules/AzureDevOpsDsc.Common/Api/Functions/Private/Authentication/ManagedIdentity/`
for why.

## The DSC v3 suite (`V3/`)

`V3/` drives the same resources through the cross-platform DSC v3 CLI instead of `Invoke-DscResource`,
exercising the adapted resource manifests `build.ps1 -Tasks dscv3` generates.

Prerequisites beyond the v2 suite's:

- **`dsc` on `PATH`** - the DSC v3 CLI, *with its adapter manifests*. An install that has `dsc.exe`
  but no `PowerShell_adapter.dsc.resource.json` answers `dsc --version` happily and then lists no
  adapter at all; `Assert-DscV3Available` fails setup by name rather than letting the resource tests
  fail one by one.
- **The manifests must exist**: run `build.ps1 -Tasks build` *and* `build.ps1 -Tasks dscv3`. Without
  the second there is nothing for `Manifests/` to check and nothing for the adapter to read.

```powershell
.\build.ps1 -Tasks build
.\build.ps1 -Tasks dscv3

cd tests\Integration\V3
.\Invoke-V3Tests.ps1 -TestFrameworkConfigurationPath '..\TestFrameworkConfiguration.local.json'
```

`-ResultsPath` overrides the NUnit XML output (default `C:\Temp\v3-integration-test-results.xml`).
`-AllowFailures` downgrades individual test failures to a warning and exits 0 - but only if the suite
genuinely ran, so a missing CLI or an unresolvable module still exits non-zero. `publish.yml` passes
it on a prerelease tag.

The suite runs `Manifests/` before `Resources/` deliberately: a bad manifest is the explanation for
the resource failures that would otherwise follow it.

### What `Manifests/` guards

`DscResource.Authoring` derives each property's JSON schema type from the AST type name, so this
module's `[System.Boolean]` convention does not match its `bool` type map and the property silently
falls back to `"string"`. The `Fix_DscAdaptedResourceManifestTypes` build task repairs that
afterwards - 25 of the 49 manifests need it - and if it ever stops running or stops matching, the
build still goes green with every boolean and numeric property typed as a string. `Manifests/`
asserts each property's schema type against the type its class declares, so that regression fails a
test instead of shipping.

### Overriding the adapter

DSC 3.2.0 renamed `Microsoft.DSC/PowerShell` to `Microsoft.Adapter/PowerShell` and drops the old name
in 4.0.0. The helpers resolve whichever the installed CLI offers, preferring the current name. Set
`DSC_V3_ADAPTER` to force one:

```powershell
$env:DSC_V3_ADAPTER = 'Microsoft.DSC/PowerShell'
```

## Running in CI

Each suite has its own workflow - `integration-tests.yml` and `integration-tests-v3.yml` - and
neither fires on push or pull request. Both are `workflow_dispatch` (run one by hand from the
Actions tab) and `workflow_call` (both gate a release from `publish.yml`). They are separate because
the v2 suite takes the better part of an hour, so learning anything about v3 from inside it meant
waiting all of v2 out first.

They target the same self-hosted runner, so they queue rather than contend - but they use **separate
cache directories** (`AzureDevOpsDscCache` and `AzureDevOpsDscCache-V3`, the latter cleared at the
start of each run). The module imports whatever cache is on disk at startup, so a shared directory
would let one suite be answered out of the other's exported state - which is exactly what running
the same resources through two hosts is supposed to rule out.

## Features an organization policy can withhold

Some resources cover Azure DevOps features an organization can turn off outright. Where that happens
the tests skip rather than fail, so a policy decision in the test organization does not read as a
product regression - and, through `publish.yml`, does not block a release.

| Feature | Resources | How it is handled |
|---|---|---|
| Classic build and release pipelines | `AzDoTaskGroup`, `AzDoDeploymentGroup` | `Enable-TestClassicPipeline` (in `Supporting/Functions/SupportingFunctions.ps1`) clears the project-level half of the "Disable creation of classic build and release pipelines" policy for the test project and reads the setting back. If an organization-level policy pins it on, the tests that create the object are skipped. |
| Real tenant user identities | `AzDoUserEntitlement`, `AzDoNotificationSubscription` | Skipped unless `AZDODSC_TEST_USER_UPN` names a real user in the organization's Entra ID tenant. The value is PII, so it is never committed - set it as a masked CI secret. |
| An external service hook endpoint | `AzDoServiceHook` | Not skipped - `AZDODSC_TEST_HOOK_URL` supplies a real endpoint when set, and otherwise a per-run `example.com` URL is used. Azure DevOps does not call the URL at create time, so the full lifecycle still runs. |
| A provisioned Event Hub | `AzDoAuditStream` | Skipped unconditionally - there is no safe placeholder connection string. |

`Enable-TestClassicPipeline` returns `$true` only when it can confirm from the API that classic
creation is genuinely enabled afterwards; a successful `PATCH` is not evidence, because Azure DevOps
accepts the request and silently leaves the value alone when an organization policy owns it.
