# Frequently Asked Questions

## General

### What is AzureDevOpsDscNative?

A PowerShell DSC module with class-based resources for managing Azure DevOps: projects, groups,
permissions, repositories, pipelines, boards, process customization, artifacts and more. It is a
fork of the DSC Community AzureDevOpsDsc module with native DSC v3 support, so every resource
works from `Invoke-DscResource` and from the `dsc` command-line tool.

### What does it need?

- PowerShell 7.0 or later, on Windows, Linux or macOS.
- An Azure DevOps organization and an identity allowed to manage what you configure.
- Network access to `dev.azure.com`.

### How do I install it?

```powershell
Install-PSResource -Name AzureDevOpsDscNative
```

### Which resources are there?

The sidebar lists every resource, and the
[README](https://github.com/ZanattaMichael/AzureDevOpsDsc#resources) groups them by area. Each
resource has its own page with its properties and examples.

### Does it work with Azure DevOps Server?

The module is built and tested against Azure DevOps Services (the cloud service). Support for
Azure DevOps Server is tracked in
[issue 91](https://github.com/ZanattaMichael/AzureDevOpsDsc/issues/91).

### I am on 1.x. What changes in 2.0?

How the credential is passed and stored. Configurations do not change. See
[Upgrading to 2.0](Upgrading-to-2.0).

## Signing in

### Which sign-in method should I use?

Managed identity on Azure machines, workload identity federation in CI such as GitHub Actions,
and a service principal with a certificate elsewhere. Use a personal access token or the Azure CLI
for local work. See [Authentication](Authentication).

### Why is there no plain-text token parameter?

A secret typed on a command line ends up in shell history, transcripts and process listings. The
token and client secret are only accepted as a `SecureString`.

### Do I sign in on every run?

No. `New-AzDoAuthenticationProvider` stores what later runs need. Sign in again to change
identity, to renew an expired credential, or to rebuild the cache.

### Can a different account run DSC from the one that signed in?

No. The stored credential is only readable by the account that wrote it. Sign in as the account
that runs DSC.

### How do I keep secrets out of my configuration?

Use a secret reference: `@{ SecretEnvironmentVariable = 'NAME' }` or
`@{ SecretName = 'Name'; SecretVault = 'Vault' }`. See
[Keeping secrets out of a configuration](https://github.com/ZanattaMichael/AzureDevOpsDsc/blob/main/USAGE.md#keeping-secrets-out-of-a-configuration).

## Running

### How do I apply a resource?

Directly with `Invoke-DscResource`, with the `dsc` command-line tool ([DSC v3](DscV3)), or across
many projects with [Dsc.PipelineRunner](LCMConfiguration).

### A resource cannot find something I can see in the portal. Why?

The module caches organization data and does not see changes made outside it. Sign in again to
rebuild the cache. See [Caching](Caching).

### Can I import what already exists?

Some resources support export, which generates configuration from the live organization. See
[Onboarding an existing organization with export](https://github.com/ZanattaMichael/AzureDevOpsDsc/blob/main/USAGE.md#onboarding-an-existing-organization-with-export).

### What happens if I leave a property out?

It is not managed. Resources only compare the properties a configuration states, so a value set
in the portal is left alone.

### Why is my run slow?

See [Slow runs and throttling](Troubleshooting#slow-runs-and-throttling-429).

## Project

### What licence is it under?

MIT.

### How do I report a bug or ask for a resource?

Open an [issue](https://github.com/ZanattaMichael/AzureDevOpsDsc/issues). Report a security
problem privately, as the
[security policy](https://github.com/ZanattaMichael/AzureDevOpsDsc/blob/main/SECURITY.md) sets out.

### How do I contribute?

Read [CONTRIBUTING.md](https://github.com/ZanattaMichael/AzureDevOpsDsc/blob/main/CONTRIBUTING.md).
[`docs/ResourceRoadmap.md`](https://github.com/ZanattaMichael/AzureDevOpsDsc/blob/main/docs/ResourceRoadmap.md)
lists what is planned.
