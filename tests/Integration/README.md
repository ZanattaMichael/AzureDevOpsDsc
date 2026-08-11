# Integration Tests

These tests exercise DSC resources against a **real** Azure DevOps organization - they create,
modify, and tear down actual resources. Only run them against a disposable/test organization.

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
