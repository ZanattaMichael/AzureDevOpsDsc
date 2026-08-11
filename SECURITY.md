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

Vulnerabilities in the upstream `dsccommunity/AzureDevOpsDsc` project that aren't specific to changes made in this fork should be reported there instead.
