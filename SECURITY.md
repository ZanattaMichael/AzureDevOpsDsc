# Security Policy

This repository is a fork of [dsccommunity/AzureDevOpsDsc](https://github.com/dsccommunity/AzureDevOpsDsc), published separately as **AzureDevOpsDscNative** to add native DSC v3 support. It is maintained by an individual, not an organization - please set expectations accordingly.

This document has three parts:

- [Reporting a vulnerability](#reporting-a-vulnerability) - for anyone who has found a problem.
- [How a report is handled](#how-a-report-is-handled) - the process the maintainer follows from report to disclosure.
- [How the module protects credentials and data](#how-the-module-protects-credentials-and-data) - what the module does on its own, and where that stops.

## Supported Versions

Security fixes are made on `main` and shipped in the next release to the PowerShell Gallery. They are not back-ported.

| Version | Supported |
|---|---|
| Latest stable release | Yes |
| Latest preview release | Yes |
| Any earlier release | No - upgrade to the latest release |

## Reporting a Vulnerability

**Please do not report security vulnerabilities through public GitHub issues, pull requests or discussions.**

Instead, use GitHub's [private vulnerability reporting](https://github.com/ZanattaMichael/AzureDevOpsDsc/security/advisories/new) feature (Security tab -> "Report a vulnerability"). This opens a private advisory visible only to you and the maintainer until a fix is ready.

Please include:

- A description of the vulnerability and its potential impact
- Steps to reproduce, or a proof of concept if available
- The affected version/commit, the PowerShell version and the operating system
- The authentication type in use (personal access token, managed identity, service principal, certificate, Azure CLI or workload identity federation)
- Which of the [built-in protections](#how-the-module-protects-credentials-and-data) did not hold, if any
- Any suggested remediation, if you have one

Never include a live credential in a report. If a real token appeared in the output you are reporting, revoke it first and replace it with a placeholder.

### In scope

- Credential/token handling (the authentication paths under `source/Modules/AzureDevOpsDsc.Common/Api/Functions/Private/Authentication/` and the token classes in `source/Classes/`)
- Anything that leaks a secret into logs, output streams, error messages, cache files or exported configuration
- Anything that sends the credential to a host that is not Azure DevOps
- Input that makes the module call an endpoint, or change a permission, other than the one the configuration describes
- Weak permissions on the files the module writes
- Build/CI supply-chain concerns (see `RequiredModules.psd1` and `.github/workflows/`)

### Out of scope

- Vulnerabilities in the upstream `dsccommunity/AzureDevOpsDsc` project that aren't specific to changes made in this fork. Report those there.
- Vulnerabilities in Azure DevOps, Microsoft Entra ID, PowerShell or DSC themselves. Report those to the [Microsoft Security Response Center](https://msrc.microsoft.com/).
- Attacks that need code already running in the same process or as the same account as the module. That code can read the token directly, and nothing in the module can prevent it.
- Attacks that need write access to the cache directory or to the DSC configuration. Both are trusted input; see [what the operator has to do](#what-the-operator-has-to-do).
- A configuration that grants more access than intended. The module applies what it is given.

## How a Report is Handled

This is the process the maintainer follows. The times are targets, kept on a best-effort basis by one person, not guarantees. Security reports are prioritized over all other work.

### 1. Acknowledge - within 7 days

The maintainer replies on the advisory to confirm the report was received and asks for anything missing. A report that arrives through a public channel is moved to a private advisory, and the public text is edited or removed if it describes how to exploit the problem.

### 2. Triage - within 14 days of the report

The maintainer reproduces the problem, decides whether it is a vulnerability in this module, and assigns a severity using [CVSS v3.1](https://www.first.org/cvss/calculator/3.1) as a guide:

| Severity | What it looks like in this module | Target for a fix |
|---|---|---|
| Critical | The credential is disclosed to another party with no local access needed, for example it is sent to a host that is not Azure DevOps. | 7 days |
| High | The credential or another secret is written somewhere others can commonly read it (a log, an error message, an output stream, a cache file with open permissions), or a permission is granted to the wrong identity. | 30 days |
| Medium | A leak or a wrong change that needs an unusual configuration or existing local access to exploit. | 90 days |
| Low | A hardening gap with no demonstrated way to exploit it. | Next regular release |

The reporter is told the outcome either way. If the report is not accepted (not reproducible, out of scope, or intended behaviour), the maintainer says why, and the reporter is free to disagree or to add detail.

### 3. Fix

- The fix is developed in the private advisory's temporary fork, or on a private branch, not in a public pull request.
- Every fix comes with a test that fails without it. A fix for a leak also extends `tests/Unit/Modules/AzureDevOpsDsc.Common/Security/SecretLeakage.tests.ps1` so the same class of problem is caught in future.
- The maintainer checks the rest of the module for the same pattern, not only the reported instance.
- The reporter is invited to review the fix before it is released.

### 4. Release and disclose

- The fix is merged and released to the PowerShell Gallery as a new version.
- `CHANGELOG.md` records it under **Security**.
- The GitHub security advisory is published with the affected versions, the fixed version, the severity, and any action users must take (for example rotating a token that may have been logged). A CVE is requested through GitHub for High and Critical issues.
- The reporter is credited in the advisory unless they ask not to be.

Disclosure is coordinated: details stay private until a fixed release is available, and the reporter is asked to do the same. If no fix is available 90 days after the report, the maintainer and the reporter agree what to publish, so that users can at least apply a workaround.

### 5. If a problem is already being exploited, or is already public

The steps above are compressed: the maintainer publishes an advisory with a workaround as soon as one is known, without waiting for the fix, and releases the fix as soon as it passes the test suite.

### If you get no reply

If there is no acknowledgement after 14 days, open a public issue that says only that you have sent a security report and are waiting for a reply. Do not include details.

## How the Module Protects Credentials and Data

The module holds a credential that can administer an Azure DevOps organization, so most of its protections are about that credential: where it is stored, where it is sent, and where it could leak.

### In memory

- Every token type (personal access token, managed identity, service principal, certificate, Azure CLI, workload identity federation) keeps its token as a `SecureString` in a hidden property. It is converted to text only when the `Authorization` header is built.
- The token's `Get()` method checks the call stack and throws unless it was called from the request path. This catches accidental use elsewhere in the module. It is not a security boundary.

### On disk

- `ModuleSettings.clixml` (the stored credential), the cache directory, every cache file and the log files are created owner-only. On Windows that is an access control list with the current user, SYSTEM and Administrators and no inheritance; on Linux and macOS it is owner-only file permissions.
- `ModuleSettings.clixml` is created empty, restricted, and only then written, so the credential is never on disk with default permissions. If the permissions cannot be restricted, `New-AzDoAuthenticationProvider` fails and writes no credential.
- On Linux and macOS the stored credential is only read when the cache directory is owned by the current account (or root) and has no group or other permissions. Otherwise the run stops, unless `AZDODSC_ALLOW_SHARED_CACHE_DIRECTORY=1` turns that into a warning.
- Tokens that can be requested again are not stored. For service principal, certificate, Azure CLI and file or GitHub Actions workload identity sign-in, no access token is written. A managed identity access token is kept only on Windows. A personal access token and a manually supplied federated token are stored, because nothing else can reproduce them.
- `New-AzDoAuthenticationProvider` only accepts a personal access token or client secret as a `SecureString`. The plain-text parameters have been removed.
- On Windows the stored credential is DPAPI-encrypted for the account that wrote it. On Linux and macOS there is no DPAPI: the credential is recoverable by anyone who can read the file, so the permissions are the only protection.
- Secret variable values, service connection keys and audit stream keys are blanked before a cache file is written.

### On the network

- Requests are refused unless they use https.
- The credential is only attached to requests for Azure DevOps hosts: `dev.azure.com`, `*.dev.azure.com` and `*.visualstudio.com`, plus any host named exactly in `AZDODSC_ALLOWED_API_HOSTS`. A request to any other host is refused before the `Authorization` header is built, so a URI taken from configuration, a cache file or an API response cannot carry the token elsewhere.
- All Azure DevOps requests go through one function, `Invoke-AzDevOpsApiRestMethod`, which is where these checks live.
- The organization name and tenant id are validated before a URI is built from them. Project names, feed names, extension ids and work item type names are escaped where they go into a request path or query, so a name cannot address a different endpoint. A continuation token taken from a response is escaped before it is put in the next request.
- Every request has a timeout (300 seconds by default), and paging stops when a response repeats its continuation token or after 10,000 pages, so a misbehaving endpoint cannot hold a run open for ever.

### In logs, errors and exported configuration

- Credential-shaped text is replaced with `<redacted>` in the verbose, warning and error streams and in the log files. The shapes recognised are `Basic`/`Bearer` header values, JSON Web Tokens, Azure DevOps personal access tokens, and `name=value` pairs with a secret-bearing name such as `client_secret` or `password`.
- The exact value of every secret the module holds is redacted too, whatever its shape: the credential it signs in with, a client secret or certificate password, each variable marked secret, and the authorization parameters of a service connection. Values shorter than eight characters are not recorded.
- Error messages built from text the module did not write (an API response body, an identity provider error, Azure CLI output) are redacted the same way, and a quoted response body is capped at 4,000 characters.
- Properties a resource declares secret are replaced with a placeholder in exported configuration, and resources log property names, not values.
- A configuration can name a secret instead of containing it. Wherever a resource takes a secret (variable group and pipeline variables, service connection authorization, service hook and audit stream consumer inputs), it accepts a reference to an environment variable or to a Microsoft.PowerShell.SecretManagement vault, so the secret is not written into the configuration document or the MOF. A reference that cannot be resolved fails the resource.

### In development and release

- `tests/Unit/Modules/AzureDevOpsDsc.Common/Security/SecretLeakage.tests.ps1` runs on every pull request. It scans the source for a secret reaching a log command or a `throw`, for web requests that bypass the audited request path, for `Invoke-Expression`, and for credential-shaped text committed to the repository. It then plants canary credentials, drives the real request, token, logging and cache code, and searches every output stream, exception, log file and cache file for them.
- GitHub Actions are pinned to a commit hash and kept current by Dependabot. Workflows run with a read-only token by default; only the publish job can write to the repository.
- The modules used to build the release are pinned to exact versions in `RequiredModules.psd1`, so a new upstream release is not picked up without a reviewed change.
- The PowerShell Gallery API key is only passed to the publish job, never to the self-hosted integration test runners. The publish job runs in a `release` environment, which lets the key sit behind a required approval.
- The publish job attests the build provenance of the package before publishing. A downloaded package can be checked with `gh attestation verify`. The module is not Authenticode signed.
- `CONTRIBUTING.md` sets out the rules contributors follow so new code keeps these properties.

### What this does not cover

- Redaction recognises credential shapes and the secret values the module itself holds. A secret it was never given, with no recognisable shape and no label, or one shorter than eight characters, is not recognised. It is a safety net behind not logging secrets, not a guarantee.
- Nothing protects against code running in the same process or as the same account: it can read the token directly.
- The cached API data held in memory, and the parts of the cache files that are not blanked, are not encrypted.
- These protections have been verified by unit tests, not by an independent audit.

### What the operator has to do

- Keep `AZDODSC_CACHE_DIRECTORY` on a private, local path, and run DSC as the account that ran `New-AzDoAuthenticationProvider`. The identity caches map names to descriptors, so anyone who can write them can redirect a permission grant.
- Prefer managed identity or workload identity federation to a personal access token, and give the identity only the access the configuration needs.
- Only name hosts you operate in `AZDODSC_ALLOWED_API_HOSTS`: every host named there receives the credential.
- Keep secrets out of configuration documents. Use a secret reference instead of a literal value; see 'Keeping Secrets out of a Configuration' in `USAGE.md`.
- Treat log files as sensitive even with redaction on, and turn verbose logging off when not troubleshooting.

See `USAGE.md` for the detail of each setting.
