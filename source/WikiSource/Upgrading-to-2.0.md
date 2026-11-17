# Upgrading to 2.0

Version 2.0.0 changes how the module accepts and stores its credential. Resource names and
properties are unchanged, so configurations do not need editing. What needs attention is the
sign-in step and, on Linux and macOS, the cache folder.

## Checklist

1. [Replace the removed plain-text parameters](#1-replace-the-removed-plain-text-parameters) in
   every script that calls `New-AzDoAuthenticationProvider`.
1. [Check anything that signs in for you](#2-check-anything-that-signs-in-for-you), such as
   Dsc.PipelineRunner.
1. [Make the cache folder private](#3-make-the-cache-folder-private) on Linux and macOS.
1. [Install 2.0 and sign in again](#4-install-20-and-sign-in-again).
1. Read [what else changed](#what-else-changed) for behaviour you may notice.

## 1. Replace the removed plain-text parameters

`New-AzDoAuthenticationProvider` no longer has `-PersonalAccessToken` (alias `-PAT`) or
`-ClientSecret`. In 1.x they only warned. In 2.0 a script that uses them stops with a
parameter-binding error such as:

```text
A parameter cannot be found that matches parameter name 'PersonalAccessToken'.
```

Pass a `SecureString` instead.

| 1.x | 2.0 |
|---|---|
| `-PersonalAccessToken 'xxxx'` or `-PAT 'xxxx'` | `-SecureStringPersonalAccessToken $securePat` |
| `-ClientSecret 'xxxx'` | `-SecureStringClientSecret $secureSecret` |

```powershell
# Before (1.x)
New-AzDoAuthenticationProvider -OrganizationName 'contoso' -PersonalAccessToken $env:AZDO_PAT

# After (2.0)
$securePat = ConvertTo-SecureString -String $env:AZDO_PAT -AsPlainText -Force
New-AzDoAuthenticationProvider -OrganizationName 'contoso' -SecureStringPersonalAccessToken $securePat
```

Interactively, use `Read-Host -AsSecureString`. From a vault, most commands already return a
`SecureString` (`Get-Secret`, `(Get-AzKeyVaultSecret ...).SecretValue`).

`-NoVerify` was only available with the plain-text personal access token. A personal access token
is not checked at sign-in, so remove `-NoVerify` from those calls.

Managed identity, certificate, Azure CLI and workload identity federation sign-in are unchanged.

## 2. Check anything that signs in for you

A wrapper that calls `New-AzDoAuthenticationProvider` with a plain-text token breaks in the same
way. Search your pipelines and scripts for `-PersonalAccessToken`, `-PAT` and `-ClientSecret`.

**Dsc.PipelineRunner:** at the time 2.0 was released, its Azure DevOps connect action and the
`Invoke-DscPipelineRunner` shim passed the token with `-PersonalAccessToken`, so
`AuthenticationType = 'PAT'` fails against 2.0 until the runner is updated. Managed identity
through the runner is not affected.

## 3. Make the cache folder private

This applies to Linux and macOS. Windows is not affected.

2.0 only reads the stored credential when the folder named by `AZDODSC_CACHE_DIRECTORY` is owned
by the account running DSC (or by root) and has no group or other access. A folder that fails the
check stops every resource with:

```text
[Assert-AzDoCachePathIsPrivate] The cache directory '...' is not private: ...
```

Fix it as the folder's owner:

```bash
chmod 700 "$AZDODSC_CACHE_DIRECTORY"
```

If the folder is owned by a different account from the one that runs DSC, sign in again as the
account that runs DSC (step 4) instead.

Where the permissions cannot be changed, for example a volume mounted into a container, set
`AZDODSC_ALLOW_SHARED_CACHE_DIRECTORY=1` to turn the failure into a warning. Only do this when
nothing else on the machine can write to the folder.

Sign-in is stricter too. If the module cannot restrict the permissions of the folder or of
`ModuleSettings.clixml`, `New-AzDoAuthenticationProvider` now fails and writes no credential. In
1.x it warned and wrote it anyway. Point `AZDODSC_CACHE_DIRECTORY` at a folder the account owns,
on a file system that supports permissions.

## 4. Install 2.0 and sign in again

```powershell
Install-PSResource -Name AzureDevOpsDscNative -Version 2.0.0

# As the account that runs DSC, with AZDODSC_CACHE_DIRECTORY set:
New-AzDoAuthenticationProvider -OrganizationName 'contoso' -SecureStringPersonalAccessToken $securePat
```

Signing in again is the recommended upgrade path. It rewrites `ModuleSettings.clixml` in the 2.0
form and rebuilds the cache. Cache files written by 1.x are still readable, so this is a clean
start, not a requirement for the cache itself.

Then confirm a resource runs:

```powershell
Invoke-DscResource -Name AzDoProject -ModuleName AzureDevOpsDscNative -Method Get -Property @{ ProjectName = 'Contoso' }
```

## What else changed

None of these need action, but you may notice them.

- **Fewer tokens on disk.** `ModuleSettings.clixml` no longer holds an access token for service
  principal, certificate, Azure CLI, or file and GitHub Actions workload identity sign-in. A
  managed identity token is kept only on Windows. A personal access token and a manually supplied
  federated token are still stored, because nothing else can reproduce them.
- **Cache files are encrypted on Windows.** Each cache file is DPAPI-encrypted for the account
  that wrote it and can no longer be opened with `Import-Clixml`. A cache folder copied to another
  machine or account has to be rebuilt by signing in there. See [Caching](Caching).
- **Secrets are removed from the cache.** Secret variable values, service connection keys and
  audit stream keys are blanked before a value is cached.
- **More is redacted in output.** The exact value of every secret the module holds is replaced
  with `<redacted>` in verbose, warning and error output and in log files. A service connection's
  tenant and client ids are shown as `<redacted>` too.
- **Requests time out.** Every request has a 300 second timeout
  (`AZDODSC_REQUEST_TIMEOUT_SECONDS`) and paging stops after 10,000 pages
  (`AZDODSC_MAX_RESPONSE_PAGES`). A request could previously wait for ever.
- **Names are escaped in request paths.** A project, feed, extension or work item type name
  containing `/`, `?` or `#` now works where it used to produce a malformed request.
- **Secret references.** Optional, and new: a configuration can name a secret instead of
  containing it. See
  [Keeping secrets out of a configuration](https://github.com/ZanattaMichael/AzureDevOpsDsc/blob/main/USAGE.md#keeping-secrets-out-of-a-configuration).

The [change log](https://github.com/ZanattaMichael/AzureDevOpsDsc/blob/main/CHANGELOG.md) has the
full list.

## If something fails

See [Troubleshooting](Troubleshooting).
