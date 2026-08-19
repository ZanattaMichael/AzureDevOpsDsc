# Authentication Guide

AzureDevOpsDscNative supports multiple authentication methods for connecting to Azure DevOps.
Authentication is configured by calling `New-AzDoAuthenticationProvider` before running any DSC
resources. This guide covers all available options.

## Supported Authentication Methods

1. **Personal Access Token (PAT)** — Most common and flexible
2. **Managed Identity** — Best for Azure-hosted resources
3. **Service Principal (Client Secret)** — For service-to-service authentication
4. **Service Principal (Certificate)** — More secure alternative to client secrets
5. **Azure CLI Token** — Use an existing `az login` session
6. **Workload Identity Federation** — Keyless authentication for CI/CD pipelines

---

## Personal Access Token (PAT)

Personal Access Tokens are scoped credentials tied to a specific Azure DevOps user account.

### Creating a PAT

1. In Azure DevOps, click your profile icon (top right)
2. Select **Personal access tokens**
3. Click **New Token**
4. Configure:
   - **Name**: Give the token a meaningful name
   - **Organization**: Select your organisation
   - **Expiration**: Set an expiration (30, 60, or 90 days, or custom)
   - **Scopes**: Select the required scopes (typically "Full access" for DSC operations)
5. Click **Create** and copy the token immediately — you will not see it again

### Configuring PAT Authentication

```powershell
# Plain-text PAT (suitable for interactive or test scripts)
New-AzDoAuthenticationProvider -OrganizationName 'my-organization' -PersonalAccessToken 'my-pat-token-here'

# SecureString PAT (preferred for production — avoids storing the plain-text value in memory)
$SecureStringPAT = Read-Host -Prompt 'Enter your PAT' -AsSecureString
New-AzDoAuthenticationProvider -OrganizationName 'my-organization' -SecureStringPersonalAccessToken $SecureStringPAT

# Skip the initial connectivity verification check (useful in CI environments)
New-AzDoAuthenticationProvider -OrganizationName 'my-organization' -PersonalAccessToken 'my-pat-token-here' -NoVerify
```

### Best Practices for PAT

- Store the PAT in a secure location (Azure Key Vault, Windows Credential Manager, PowerShell SecretStore)
- Use the minimum required scopes
- Set a reasonable expiration date (30–90 days) and rotate regularly
- Never commit a PAT to version control or hardcode it in a script

---

## Managed Identity

Managed Identity is the recommended approach when running DSC configurations on Azure resources
(Virtual Machines, Azure Arc-enabled servers, Azure Automation, etc.). No credentials or secrets
need to be stored — the identity is provided by the Azure platform.

### Prerequisites

- The hosting resource must have a System-assigned or User-assigned Managed Identity enabled
- The Managed Identity must be added to the Azure DevOps organisation with appropriate permissions

### Configuring Managed Identity Authentication

```powershell
# Authenticate using the Managed Identity assigned to the current Azure resource
New-AzDoAuthenticationProvider -OrganizationName 'my-organization' -useManagedIdentity

# Skip the initial connectivity verification check
New-AzDoAuthenticationProvider -OrganizationName 'my-organization' -useManagedIdentity -NoVerify
```

### Best Practices for Managed Identity

- Prefer System-assigned identity when only one resource needs access
- Apply the principle of least privilege — grant the minimum permissions required
- No token rotation is needed; tokens are issued and refreshed by the Azure platform
- Audit identity access regularly

---

## Service Principal (Client Secret)

Service Principals are ideal for non-Azure environments, CI/CD pipelines, and cross-tenant scenarios
where Managed Identity is not available.

### Prerequisites

- An Azure AD App Registration with a Client Secret
- The Service Principal (Enterprise Application) must be added to the Azure DevOps organisation with
  appropriate permissions via Access Control

### Configuring Service Principal Authentication

```powershell
# Plain-text client secret
New-AzDoAuthenticationProvider `
    -OrganizationName 'my-organization' `
    -TenantId         '00000000-0000-0000-0000-000000000000' `
    -ClientId         'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee' `
    -ClientSecret     'my-client-secret-value'

# SecureString client secret (preferred for production)
$SecureSecret = Read-Host -Prompt 'Enter client secret' -AsSecureString
New-AzDoAuthenticationProvider `
    -OrganizationName           'my-organization' `
    -TenantId                   '00000000-0000-0000-0000-000000000000' `
    -ClientId                   'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee' `
    -SecureStringClientSecret   $SecureSecret

# Skip the initial connectivity verification check
New-AzDoAuthenticationProvider `
    -OrganizationName 'my-organization' `
    -TenantId         '00000000-0000-0000-0000-000000000000' `
    -ClientId         'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee' `
    -ClientSecret     'my-client-secret-value' `
    -NoVerify
```

### Best Practices for Service Principal

- Store client secrets in Azure Key Vault or PowerShell SecretStore — never in code or config files
- Rotate secrets regularly
- Prefer certificate-based authentication (see below) for higher-security scenarios
- Grant minimal required permissions

---

## Service Principal (Certificate)

Certificate-based authentication is more secure than client secrets because private keys never leave
the machine and certificates can be stored in the Windows Certificate Store or as PFX files.

### Prerequisites

- An Azure AD App Registration with an uploaded certificate (public key)
- The private key must be available on the machine running DSC (certificate store or PFX file)
- The Service Principal must be added to the Azure DevOps organisation with appropriate permissions

### Configuring Certificate Authentication

```powershell
# ── Windows certificate store (thumbprint) ──────────────────────────────────
# The certificate must be present in the local machine or current user certificate store.
New-AzDoAuthenticationProvider `
    -OrganizationName        'my-organization' `
    -TenantId                '00000000-0000-0000-0000-000000000000' `
    -ClientId                'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee' `
    -CertificateThumbprint   'AABBCCDDEEFF00112233445566778899AABBCCDD'

# ── PFX file (cross-platform — Linux, macOS, and Windows) ───────────────────
$CertPassword = Read-Host -Prompt 'Enter PFX password' -AsSecureString

New-AzDoAuthenticationProvider `
    -OrganizationName    'my-organization' `
    -TenantId            '00000000-0000-0000-0000-000000000000' `
    -ClientId            'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee' `
    -CertificatePath     '/etc/azdo-dsc/auth.pfx' `
    -CertificatePassword $CertPassword

# Skip the initial connectivity verification check (either mode)
New-AzDoAuthenticationProvider `
    -OrganizationName        'my-organization' `
    -TenantId                '00000000-0000-0000-0000-000000000000' `
    -ClientId                'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee' `
    -CertificateThumbprint   'AABBCCDDEEFF00112233445566778899AABBCCDD' `
    -NoVerify
```

### Best Practices for Certificates

- Store the private key securely — Windows Certificate Store (LocalMachine\My) or a protected PFX file
- Monitor certificate expiration and rotate before it expires
- Use a unique certificate per environment (Dev/Staging/Production)
- Do not share certificates across service principals

---

## Azure CLI Token

Acquires a Bearer token from an existing `az login` session without requiring any additional
credentials. Particularly useful for local development and interactive sessions.

### Prerequisites

- The Azure CLI must be installed and available in `PATH`
- You must be signed in: run `az login` (or `az login --use-device-code` in headless environments)
- The signed-in account must have access to the Azure DevOps organisation
- Run `az account show` to verify the active context; use `az account set --subscription <id>` to switch

### Configuring Azure CLI Authentication

```powershell
# Authenticate using the active Azure CLI session
New-AzDoAuthenticationProvider -OrganizationName 'my-organization' -useAzureCLI

# Skip the initial connectivity verification check
New-AzDoAuthenticationProvider -OrganizationName 'my-organization' -useAzureCLI -NoVerify
```

### Best Practices for Azure CLI

- Suitable for local development and interactive sessions
- Token is automatically refreshed by the CLI; no manual credential management required
- Not recommended for automated/unattended scenarios — use a Service Principal or Managed Identity instead
- Only works on machines with the Azure CLI installed

---

## Workload Identity Federation

Keyless authentication for GitHub Actions, Kubernetes/AKS, Azure DevOps Pipelines, and any
OIDC-compliant system. A short-lived JWT issued by the external identity provider is exchanged for
an Azure AD access token — no client secret or certificate is required on the App Registration.

Three token sources are supported:

| Mode | Description |
|------|-------------|
| **File-based** | Token is read from a projected file path (Kubernetes/AKS Workload Identity) |
| **GitHub Actions OIDC** | Token is requested from the GitHub Actions runtime endpoint automatically |
| **Manual token** | Caller supplies a federated JWT obtained from another OIDC source |

### Prerequisites

- An Azure AD App Registration with a Federated Identity Credential configured for the appropriate
  issuer and subject
- The Service Principal must be added to the Azure DevOps organisation with required permissions

### Configuring Workload Identity Federation

```powershell
# ── 1. File-based token (Kubernetes / AKS Workload Identity) ─────────────────
# AKS projects the service-account token at the path in AZURE_FEDERATED_TOKEN_FILE.
New-AzDoAuthenticationProvider `
    -OrganizationName    'my-organization' `
    -TenantId            '00000000-0000-0000-0000-000000000000' `
    -ClientId            'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee' `
    -FederatedTokenFile  $ENV:AZURE_FEDERATED_TOKEN_FILE

# Hard-coded file path variant
New-AzDoAuthenticationProvider `
    -OrganizationName    'my-organization' `
    -TenantId            '00000000-0000-0000-0000-000000000000' `
    -ClientId            'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee' `
    -FederatedTokenFile  '/var/run/secrets/azure/tokens/azure-identity-token'

# ── 2. GitHub Actions OIDC ────────────────────────────────────────────────────
# The workflow must grant `id-token: write` permission.
# ACTIONS_ID_TOKEN_REQUEST_URL and ACTIONS_ID_TOKEN_REQUEST_TOKEN are injected
# automatically by GitHub Actions when that permission is present.
#
# GitHub Actions workflow snippet:
#   permissions:
#     id-token: write
#     contents: read
New-AzDoAuthenticationProvider `
    -OrganizationName       'my-organization' `
    -TenantId               '00000000-0000-0000-0000-000000000000' `
    -ClientId               'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee' `
    -useGitHubActionsOIDC

# Custom audience (must match the federated identity credential audience in Azure AD)
New-AzDoAuthenticationProvider `
    -OrganizationName       'my-organization' `
    -TenantId               '00000000-0000-0000-0000-000000000000' `
    -ClientId               'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee' `
    -useGitHubActionsOIDC `
    -GitHubActionsAudience  'api://AzureADTokenExchange'

# ── 3. Manually-supplied federated token ─────────────────────────────────────
# Use when the OIDC token has already been acquired externally (e.g. Azure DevOps
# Pipelines OIDC service connection) and is available as a variable.
$FederatedJWT = $ENV:SYSTEM_OIDCTOKEN | ConvertTo-SecureString -AsPlainText -Force

New-AzDoAuthenticationProvider `
    -OrganizationName  'my-organization' `
    -TenantId          '00000000-0000-0000-0000-000000000000' `
    -ClientId          'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee' `
    -FederatedToken    $FederatedJWT

# ── Skip connectivity verification (any mode) ─────────────────────────────────
New-AzDoAuthenticationProvider `
    -OrganizationName    'my-organization' `
    -TenantId            '00000000-0000-0000-0000-000000000000' `
    -ClientId            'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee' `
    -FederatedTokenFile  '/var/run/secrets/azure/tokens/azure-identity-token' `
    -NoVerify
```

### Best Practices for Workload Identity

- No secrets stored in CI/CD — tokens are short-lived and issued on demand
- Recommended for modern CI/CD systems (GitHub Actions, Azure DevOps Pipelines, AKS)
- Manually-supplied tokens are not automatically refreshed; call `New-AzDoAuthenticationProvider`
  again with a fresh token when the current one expires

---

## Storing Credentials Securely

Before passing credentials to `New-AzDoAuthenticationProvider`, retrieve them from a secure store
rather than hardcoding them.

### Option 1: Azure Key Vault

```powershell
# Retrieve PAT from Key Vault
$token = (Get-AzKeyVaultSecret -VaultName 'MyKeyVault' -Name 'AzureDevOpsPAT').SecretValue
New-AzDoAuthenticationProvider -OrganizationName 'my-organization' -SecureStringPersonalAccessToken $token
```

### Option 2: PowerShell SecretStore

```powershell
# Install SecretStore module
Install-Module Microsoft.PowerShell.SecretStore

# Store credential (one-time setup)
Set-Secret -Name AzureDevOpsPAT -Secret 'your-pat-token' -Vault SecretStore

# Retrieve in script
$token = Get-Secret -Name AzureDevOpsPAT -AsPlainText
New-AzDoAuthenticationProvider -OrganizationName 'my-organization' -PersonalAccessToken $token
```

### Option 3: Windows Credential Manager (Windows only)

```powershell
# Store PAT in Credential Manager (one-time setup)
$cred = New-Object System.Management.Automation.PSCredential(
    'AzureDevOpsDsc',
    (ConvertTo-SecureString 'your-pat-token' -AsPlainText -Force)
)
$cred | Export-Clixml -Path "$env:APPDATA\AzureDevOpsDsc\cred.xml"

# Retrieve in script
$cred = Import-Clixml -Path "$env:APPDATA\AzureDevOpsDsc\cred.xml"
New-AzDoAuthenticationProvider -OrganizationName 'my-organization' -SecureStringPersonalAccessToken $cred.Password
```

---

## Choosing the Right Authentication Method

| Method | Best For | Pros | Cons |
|--------|----------|------|------|
| **PAT** | Local dev, general use | Simple, no Azure AD required | Requires token management and rotation |
| **Managed Identity** | Azure VMs, Arc, Automation | No credentials to manage, secure | Azure-hosted resources only |
| **Service Principal (secret)** | CI/CD, on-premises automation | Works anywhere | Secret management required |
| **Service Principal (cert)** | High-security scenarios | More secure than secrets | More complex certificate lifecycle |
| **Azure CLI** | Local development | Automatic, uses existing login | Not suitable for automation |
| **Workload Identity** | GitHub Actions, AKS, ADO Pipelines | Keyless, short-lived tokens | Requires OIDC federation setup |

---

## Troubleshooting Authentication

### "Authentication Failed"

Verify the token or credentials are correct and have not expired. For PAT, check that the token
still exists in Azure DevOps and has the required scopes.

### "Insufficient Permissions"

The authenticated identity lacks the necessary permissions in Azure DevOps:
- Check group memberships and permission assignments for the identity
- For PAT, review the token scopes (Full access or specific scopes required)

### "Token Expired"

- **PAT**: Create a new token in Azure DevOps
- **Service Principal secret**: Rotate the secret in Azure AD
- **Azure CLI**: Re-run `az login`
- **Workload Identity (manual)**: Acquire a fresh federated token

### Module or Resource Not Found

```powershell
# Verify the module is installed
Get-Module -ListAvailable | Where-Object Name -eq AzureDevOpsDscNative

# Import explicitly if needed
Import-Module -Name AzureDevOpsDscNative
```

---

## Security Checklist

- [ ] Use the minimum required permissions for the authenticated identity
- [ ] Store all credentials in a secure vault — never in code or config files
- [ ] Set expiration dates on PATs and rotate them regularly
- [ ] Rotate service principal secrets before they expire
- [ ] Monitor authentication logs and audit access regularly
- [ ] Revoke unused credentials and service principals
- [ ] Use MFA for personal accounts (PAT is tied to the user account)
- [ ] Prefer Managed Identity or Workload Identity over long-lived secrets where possible
