# CI/CD — GitHub Actions

Three workflows automate testing, building, and publishing the module.

---

## Workflow overview

| Workflow | File | Trigger | Runner |
|---|---|---|---|
| Unit Tests | `unit-tests.yml` | Push to `main`, every PR, manual | `windows-latest` |
| Build & Publish | `build-publish.yml` | Push to `main`, every PR, version tags, manual | `windows-latest` |
| Integration Tests | `integration-tests.yml` | Manual only (requires approval) | `AZDO-AGENT` (self-hosted) |

---

## Unit Tests

Runs both Pester test suites on every pull request and push to `main`.

**What it does:**
1. Installs Pester 5.7.1
2. Runs `./azuredevopsdsc.tests.ps1` (class-level tests)
3. Runs `./azuredevopsdsc.common.tests.ps1` (module-level tests)
4. Uploads test logs as artifacts

No secrets or variables required.

---

## Build & Publish

Builds the module on every PR (validation) and publishes to the
PowerShell Gallery on version tags.

**What it does:**
1. Runs `.\build.ps1 -Tasks noop -ResolveDependency` to install build tools
2. Runs `.\build.ps1 -Tasks build` to compile the module
3. Uploads the built module as a workflow artifact
4. **On version tags only** (`v*.*.*`): publishes to PSGallery using `PS_GALLERY_API_KEY`

**Required secret:**

| Secret | Description |
|---|---|
| `PS_GALLERY_API_KEY` | PowerShell Gallery API key for `Publish-Module` |

**To publish a release:**

```powershell
git tag v1.2.3
git push origin v1.2.3
```

This triggers the build and then the publish step automatically.

---

## Integration Tests

Runs the full integration test suite against a live Azure DevOps organization.
The workflow is **manual-only** and gated behind a GitHub Environment that
requires project-owner approval before any code executes on the runner.

### Environment protection setup (one-time)

1. Open **Settings → Environments** in the repository.
2. Create an environment named **`integration`**.
3. Add the project owner as a **required reviewer**.
4. Optionally restrict deployments to specific branches.

Until an approver clicks **Approve** in the GitHub UI, the job waits and
nothing runs on the `AZDO-AGENT` runner.

### Required secrets and variables

| Type | Name | Description |
|---|---|---|
| Variable | `AzureDevOpsOrg` | Azure DevOps organization name |
| Secret | `AZURE_DEVOPS_PAT` | PAT with full-access scopes *(omit to use Managed Identity)* |

**Add these under Settings → Secrets and variables → Actions.**

### What it does

1. Checks out the repository
2. Installs build dependencies and builds the module
3. Adds the build output to `$env:PSModulePath`
4. Writes `TestFrameworkConfiguration.json` dynamically from the variable/secret
   (no credentials stored in source)
5. Creates the cache directory (`$env:TEMP\AzureDevOpsDscCache`)
6. Runs `tests/Integration/Invoke-Tests.ps1`
7. Uploads `C:\Temp\integration-test-results.xml` as an artifact

### Running manually

1. Go to **Actions → Integration Tests** in the repository.
2. Click **Run workflow**.
3. A notification is sent to all required reviewers.
4. Once approved the job starts on `AZDO-AGENT`.

### Self-hosted runner setup

The integration tests require a Windows self-hosted runner registered with the
label **`AZDO-AGENT`**.

```powershell
# Download and configure the runner agent from:
# Settings → Actions → Runners → New self-hosted runner

# Register with the required label
./config.cmd --url https://github.com/ZanattaMichael/AzureDevOpsDsc `
             --token <registration-token> `
             --labels AZDO-AGENT `
             --runnergroup Default
```

If the runner is an Azure VM or Arc-enabled machine you can omit
`AZURE_DEVOPS_PAT` and use Managed Identity instead — the workflow
auto-detects an empty secret and sets `AuthenticationType = ManagedIdentity`.
