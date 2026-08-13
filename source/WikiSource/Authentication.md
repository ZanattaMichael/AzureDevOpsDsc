# Authentication

`New-AzDoAuthenticationProvider` is the single entry point for all authentication
methods. Call it once before using any DSC resources. It stores credentials
in `$env:AZDODSC_CACHE_DIRECTORY\ModuleSettings.clixml` so that DSC resources
can restore them automatically when running in isolated PowerShell runspaces.

---

## Prerequisites

Set the cache directory before authenticating:

```powershell
$env:AZDODSC_CACHE_DIRECTORY = "$env:LOCALAPPDATA\AzureDevOpsDscCache"
New-Item -Path $env:AZDODSC_CACHE_DIRECTORY -ItemType Directory -Force | Out-Null
```

---

## Authentication methods

### 1. Personal Access Token (PAT)

The simplest method — generate a PAT in Azure DevOps under
**User settings → Personal access tokens** with the required scopes.

```powershell
# Plain text (for testing only)
New-AzDoAuthenticationProvider -OrganizationName 'myorg' -PersonalAccessToken '<pat>'

# SecureString (recommended)
$securePat = Read-Host 'PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'myorg' -SecureStringPersonalAccessToken $securePat
```

The PAT is DPAPI-encrypted when stored in `ModuleSettings.clixml` on Windows.

---

### 2. Managed Identity

Use when running on an **Azure VM**, **Arc-enabled server**, or any resource with
a system-assigned or user-assigned managed identity. No credentials need to be
stored — the IMDS endpoint provides the token automatically.

```powershell
New-AzDoAuthenticationProvider -OrganizationName 'myorg' -useManagedIdentity
```

The managed identity must be granted access to the Azure DevOps organization.
See the [Microsoft documentation](https://learn.microsoft.com/en-us/azure/devops/integrate/get-started/authentication/service-principal-managed-identity?view=azure-devops)
for how to add a managed identity to an Azure DevOps organization.

Token refresh is handled automatically when `isExpired()` returns `$true`.

---

### 3. Service Principal — Client Secret

Authenticate as an Azure AD application using a client secret.

```powershell
# Plain text client secret
New-AzDoAuthenticationProvider -OrganizationName 'myorg' `
    -TenantId  '<tenant-id>' `
    -ClientId  '<client-id>' `
    -ClientSecret '<secret>'

# SecureString client secret (recommended)
$secureSecret = Read-Host 'Client secret' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'myorg' `
    -TenantId              '<tenant-id>' `
    -ClientId              '<client-id>' `
    -SecureStringClientSecret $secureSecret
```

The client secret is encrypted in `ModuleSettings.clixml`. Tokens are refreshed
automatically on expiry without re-reading the secret.

---

### 4. Service Principal — Certificate

Authenticate as an Azure AD application using a certificate. Two modes are
supported.

**Windows certificate store** (thumbprint, Windows-only):

```powershell
New-AzDoAuthenticationProvider -OrganizationName 'myorg' `
    -TenantId              '<tenant-id>' `
    -ClientId              '<client-id>' `
    -CertificateThumbprint '<thumbprint>'
```

The certificate must already be installed in the current user's or local
machine's certificate store.

**PFX file** (cross-platform):

```powershell
$certPassword = Read-Host 'PFX password' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'myorg' `
    -TenantId             '<tenant-id>' `
    -ClientId             '<client-id>' `
    -CertificatePath      '/path/to/cert.pfx' `
    -CertificatePassword  $certPassword
```

---

### 5. Azure CLI

Reuses the token from an active `az login` session. Requires the
[Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
to be installed and authenticated.

```powershell
# Log in once with the CLI
az login

# Then authenticate the DSC module
New-AzDoAuthenticationProvider -OrganizationName 'myorg' -useAzureCLI
```

Tokens are fetched from `az account get-access-token` and refreshed
automatically on expiry.

---

### 6. Workload Identity Federation

Use an external OIDC identity (GitHub Actions, Kubernetes/AKS, etc.) to obtain
an Azure AD token without storing any secret. Requires a **federated credential**
configured on the Azure AD application.

**AKS / Kubernetes workload identity (token file)**:

```powershell
# The token file is projected and periodically rotated by the kubelet.
New-AzDoAuthenticationProvider -OrganizationName 'myorg' `
    -TenantId           '<tenant-id>' `
    -ClientId           '<client-id>' `
    -FederatedTokenFile '/var/run/secrets/azure/tokens/azure-identity-token'
```

**GitHub Actions OIDC**:

```powershell
# Must be called inside a GitHub Actions job with id-token: write permission.
New-AzDoAuthenticationProvider -OrganizationName 'myorg' `
    -TenantId  '<tenant-id>' `
    -ClientId  '<client-id>' `
    -useGitHubActionsOIDC
```

**Manual / caller-supplied token** (e.g. Azure DevOps Pipelines OIDC step):

```powershell
New-AzDoAuthenticationProvider -OrganizationName 'myorg' `
    -TenantId        '<tenant-id>' `
    -ClientId        '<client-id>' `
    -FederatedToken  $oidcToken
```

> **Note**: Manual tokens cannot be refreshed automatically. When the token
> expires you must call `New-AzDoAuthenticationProvider` again with a fresh token.

---

## DSC runspace isolation

`Invoke-DscResource` executes each DSC method (`Get`/`Set`/`Test`) in an
isolated PowerShell runspace. Global variables set in your calling session do
not carry over.

`Add-AuthenticationHTTPHeader` (called internally on every API request)
detects this scenario — when `$Global:DSCAZDO_AuthenticationToken` is `$null`
it automatically restores the token from `ModuleSettings.clixml` using the same
authentication method that was originally used. All six methods are supported
for automatic restoration except Workload Identity Federation **Manual** tokens
(which require the caller to re-supply the token).

---

## Verifying authentication

```powershell
# Inspect the live token object
$Global:DSCAZDO_AuthenticationToken

# Check the token type and expiry
$Global:DSCAZDO_AuthenticationToken.tokenType
$Global:DSCAZDO_AuthenticationToken.isExpired()

# Retrieve the raw Authorization header value
Add-AuthenticationHTTPHeader
```
