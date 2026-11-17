# Authentication Guide

`New-AzDoAuthenticationProvider` signs the module in to one Azure DevOps organization. Run it once,
as the account that will run DSC. It stores the credential in `AZDODSC_CACHE_DIRECTORY`, builds the
[cache](Caching), and every resource run after that signs in again from what was stored.

This page covers the setup on both sides: what to create in Azure DevOps and Microsoft Entra ID,
and the command to run.

> **Upgrading from 1.x?** The plain-text `-PersonalAccessToken` and `-ClientSecret` parameters
> were removed in 2.0. See [Upgrading to 2.0](Upgrading-to-2.0).

## Before you sign in

### Set `AZDODSC_CACHE_DIRECTORY`

The command throws if the variable is not set.

```powershell
$env:AZDODSC_CACHE_DIRECTORY = Join-Path $HOME '.azuredevopsdsc'
```

Treat the folder as credential storage:

- Use a private, local path that the account running DSC owns. Not a shared folder, and not a
  network share.
- The module creates the folder if it is missing and sets owner-only permissions on it. If it
  cannot restrict the permissions, it fails and writes no credential.
- On Linux and macOS the folder must be owned by the current account (or root) with no group or
  other access (`chmod 700`), or resources refuse to read it.
- Set the variable for every process that runs DSC (the service, the pipeline job, the `dsc`
  command), not only for the session that signs in.

### Pass the organization name, not its URL

For `https://dev.azure.com/contoso`, pass `-OrganizationName 'contoso'`. Anything that is not 1 to
50 letters, digits or hyphens is refused before a token is requested.

### Give the identity access in Azure DevOps

Whatever method you choose, the identity (a user for a personal access token, otherwise a service
principal or managed identity) needs two things in Azure DevOps:

1. **Membership of the organization.** For a service principal or managed identity, the
   organization must be connected to the Microsoft Entra tenant the identity lives in. Add it under
   **Organization settings > Users > Add users**, searching for its display name, and give it an
   access level (for example Basic). Microsoft's guide is
   [Use service principals and managed identities in Azure DevOps](https://learn.microsoft.com/azure/devops/integrate/get-started/authentication/service-principal-managed-identity).
1. **Permission to do what the configuration asks.** The module can only do what the identity is
   allowed to do. As a rule:
    - Organization-level resources (organization groups and permissions, organization settings,
      agent pools, extensions, audit streams, processes, entitlements) need membership of
      **Project Collection Administrators**.
    - Project-level resources need **Project Administrators** in each project, or Project
      Collection Administrators to create projects.

Sign-in also reads the organization to build the cache: projects, groups, users, group members,
repositories, security namespaces, service principals and process templates. The identity has to
be able to read those.

Prefer managed identity or workload identity federation to a personal access token. They leave no
long-lived secret to store or rotate.

## Sign-in methods

| Method | Use it for | Stored in the cache folder |
|---|---|---|
| [Managed identity](#managed-identity) | Azure VMs and Azure Arc machines | Nothing that needs rotating |
| [Workload identity federation](#workload-identity-federation) | GitHub Actions, AKS, other OIDC issuers | Nothing, except a manually supplied token |
| [Service principal with a certificate](#service-principal-with-a-certificate) | Unattended runs outside Azure | The certificate reference (and the PFX password) |
| [Service principal with a client secret](#service-principal-with-a-client-secret) | Unattended runs outside Azure | The client secret |
| [Azure CLI](#azure-cli) | Local development | Nothing |
| [Personal access token](#personal-access-token) | Local development and small setups | The token |

All methods except the personal access token check the connection when you sign in. Add
`-NoVerify` to skip that check. A personal access token is not checked at sign-in, so a wrong or
expired token only shows up when the cache is built or a resource runs. `-NoVerify` is accepted
with a personal access token too, where it has nothing to skip.

### Managed identity

**Set up:** enable a system-assigned or user-assigned managed identity on the machine, then add
that identity to the organization as described above.

```powershell
New-AzDoAuthenticationProvider -OrganizationName 'contoso' -useManagedIdentity
```

### Workload identity federation

A short-lived token from an external issuer is exchanged for a Microsoft Entra access token, so
the app registration needs no secret or certificate.

**Set up:**

1. Create an app registration in Microsoft Entra ID and note its tenant id and client id.
1. Under **Certificates & secrets > Federated credentials**, add a credential for your issuer. For
   GitHub Actions choose the GitHub Actions scenario and name the repository and the branch,
   environment or tag that will run the job. Keep the audience `api://AzureADTokenExchange`.
1. Add the app's service principal to the Azure DevOps organization as described above.

**GitHub Actions.** The job needs `id-token: write`:

```yaml
permissions:
  id-token: write
  contents: read
```

```powershell
New-AzDoAuthenticationProvider -OrganizationName 'contoso' `
    -TenantId '00000000-0000-0000-0000-000000000000' `
    -ClientId 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee' `
    -useGitHubActionsOIDC
```

Pass `-GitHubActionsAudience` only if the federated credential uses a different audience.

**A token file** (AKS workload identity projects one at `AZURE_FEDERATED_TOKEN_FILE`):

```powershell
New-AzDoAuthenticationProvider -OrganizationName 'contoso' `
    -TenantId '00000000-0000-0000-0000-000000000000' `
    -ClientId 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee' `
    -FederatedTokenFile $env:AZURE_FEDERATED_TOKEN_FILE
```

**A token you already hold** (for example from an Azure Pipelines service connection):

```powershell
$federatedToken = ConvertTo-SecureString -String $env:SYSTEM_OIDCTOKEN -AsPlainText -Force

New-AzDoAuthenticationProvider -OrganizationName 'contoso' `
    -TenantId '00000000-0000-0000-0000-000000000000' `
    -ClientId 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee' `
    -FederatedToken $federatedToken
```

A manually supplied token cannot be renewed by the module. Sign in again with a fresh token when
it expires.

### Service principal with a certificate

**Set up:** create an app registration, upload the certificate's public key under
**Certificates & secrets > Certificates**, and add the service principal to the organization. The
private key stays on the machine that runs DSC.

```powershell
# Windows certificate store
New-AzDoAuthenticationProvider -OrganizationName 'contoso' `
    -TenantId '00000000-0000-0000-0000-000000000000' `
    -ClientId 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee' `
    -CertificateThumbprint 'AABBCCDDEEFF00112233445566778899AABBCCDD'

# PFX file, on any platform
$pfxPassword = Read-Host -Prompt 'PFX password' -AsSecureString

New-AzDoAuthenticationProvider -OrganizationName 'contoso' `
    -TenantId '00000000-0000-0000-0000-000000000000' `
    -ClientId 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee' `
    -CertificatePath '/etc/azdo-dsc/auth.pfx' `
    -CertificatePassword $pfxPassword
```

### Service principal with a client secret

**Set up:** create an app registration, add a client secret under **Certificates & secrets**, and
add the service principal to the organization.

The secret is only accepted as a `SecureString`. There is no plain-text `-ClientSecret` parameter.

```powershell
$clientSecret = Read-Host -Prompt 'Client secret' -AsSecureString

New-AzDoAuthenticationProvider -OrganizationName 'contoso' `
    -TenantId '00000000-0000-0000-0000-000000000000' `
    -ClientId 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee' `
    -SecureStringClientSecret $clientSecret
```

### Azure CLI

Uses the account already signed in with `az login`. The Azure CLI must be on `PATH`, and the
account must be a member of the organization.

```powershell
New-AzDoAuthenticationProvider -OrganizationName 'contoso' -useAzureCLI
```

Every resource run asks the Azure CLI for a new token, so this is for interactive use, not for
unattended runs.

### Personal access token

**Set up:** in Azure DevOps open **User settings > Personal access tokens > New Token**, choose
the organization and an expiry, and select scopes. A full-access token is the simplest choice for
a configuration that spans many areas. A scoped token has to cover every area the configuration
manages, and the reads the cache makes at sign-in (listed above).

The token is only accepted as a `SecureString`. There is no plain-text `-PersonalAccessToken`
parameter.

```powershell
# Interactive
$pat = Read-Host -Prompt 'Personal access token' -AsSecureString

# Or from an environment variable set by a pipeline or secret store
$pat = ConvertTo-SecureString -String $env:AZDO_PAT -AsPlainText -Force

New-AzDoAuthenticationProvider -OrganizationName 'contoso' -SecureStringPersonalAccessToken $pat
```

A token acts as the user who created it and stops working when that user leaves or the token
expires. Rotate it by signing in again with the new token.

## Reading the credential from a secret store

```powershell
# Azure Key Vault
$pat = (Get-AzKeyVaultSecret -VaultName 'MyKeyVault' -Name 'AzureDevOpsPAT').SecretValue

# Microsoft.PowerShell.SecretManagement (returns a SecureString by default)
$pat = Get-Secret -Name 'AzureDevOpsPAT'

New-AzDoAuthenticationProvider -OrganizationName 'contoso' -SecureStringPersonalAccessToken $pat
```

This is about the credential the module signs in with. To keep the secrets a *resource* manages
(variable group values, service connection keys) out of a configuration, use a secret reference:
see [Keeping secrets out of a configuration](https://github.com/ZanattaMichael/AzureDevOpsDsc/blob/main/USAGE.md#keeping-secrets-out-of-a-configuration).

## What is stored, and where

`New-AzDoAuthenticationProvider` writes `ModuleSettings.clixml` in the cache folder. It holds the
organization name and what a later run needs to sign in again.

- On Windows the stored values are DPAPI-encrypted for the account that wrote them. Another
  account, or the same account on another machine, cannot read them.
- On Linux and macOS there is no DPAPI. The stored credential is recoverable by anyone who can
  read the file, so the owner-only permissions are the only protection.
- Access tokens that can be requested again are not stored.

Run DSC as the account that signed in. To change organization, identity or method, run
`New-AzDoAuthenticationProvider` again. The
[security policy](https://github.com/ZanattaMichael/AzureDevOpsDsc/blob/main/SECURITY.md#how-the-module-protects-credentials-and-data)
has the full detail.

## When sign-in fails

See [Troubleshooting](Troubleshooting#sign-in-and-credentials).
