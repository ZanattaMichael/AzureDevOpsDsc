## Security

This repository is a fork of [dsccommunity/AzureDevOpsDsc](https://github.com/dsccommunity/AzureDevOpsDsc), published separately as **AzureDevOpsDscNative** to add native DSC v3 support. It is maintained by an individual, not an organization - please set expectations accordingly.

## Reporting a Vulnerability

**Please do not report security vulnerabilities through public GitHub issues.**

Instead, use GitHub's [private vulnerability reporting](https://github.com/ZanattaMichael/AzureDevOpsDsc/security/advisories/new) feature (Security tab -> "Report a vulnerability"). This opens a private advisory visible only to the maintainer until a fix is ready.

Please include:

- A description of the vulnerability and its potential impact
- Steps to reproduce, or a proof of concept if available
- The affected version/commit
- Any suggested remediation, if you have one

There's no guaranteed response time - this is maintained on a best-effort basis - but security reports will be prioritized over other issues.

## Scope

This module manages Azure DevOps resources via PowerShell DSC and the Azure DevOps REST API. Security-relevant areas include:

- Credential/token handling (Managed Identity, service principal, certificate, and Azure CLI authentication paths under `source/Modules/AzureDevOpsDsc.Common/Api/Functions/Private/Authentication/`)
- Anything that could leak secrets into logs, cache files, or error messages
- Build/CI supply-chain concerns (see `RequiredModules.psd1` and `.github/workflows/`)

## Built-in protections

What the module does on its own, so a report can say which of these did not hold:

- **Credential storage.** `ModuleSettings.clixml`, the cache and the log files are created owner-only. On Windows the stored credential is DPAPI-encrypted; on Linux and macOS it is recoverable by anyone who can read the file, so the permissions are the protection. See `USAGE.md`.
- **Credential destination.** The credential is only attached to requests for Azure DevOps hosts (`dev.azure.com`, `*.dev.azure.com`, `*.visualstudio.com`, plus any host named in `AZDODSC_ALLOWED_API_HOSTS`), over https.
- **Redaction.** Credential-shaped text is replaced with `<redacted>` in the verbose, warning and error streams, the log files, and error messages built from API responses, identity provider errors and Azure CLI output. This is pattern based and is a safety net, not a guarantee.
- **Cache contents.** Secret variable values, service connection keys and audit stream keys are blanked before a cache file is written.
- **Export.** Properties a resource declares secret are replaced with a placeholder in exported configuration.
- **Input checks.** The organization name and tenant id are validated before a URI is built from them, and a continuation token taken from a response is escaped.

`tests/Unit/Modules/AzureDevOpsDsc.Common/Security/SecretLeakage.tests.ps1` checks these on every pull request, by scanning the source and by planting canary credentials and searching all output for them.

None of this protects against code running in the same process or account as the module: it can read the token directly.

Vulnerabilities in the upstream `dsccommunity/AzureDevOpsDsc` project that aren't specific to changes made in this fork should be reported there instead.
