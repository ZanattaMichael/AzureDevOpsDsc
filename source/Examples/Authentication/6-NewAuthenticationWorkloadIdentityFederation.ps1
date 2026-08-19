<#
    .DESCRIPTION
        This example shows how to authenticate with Azure DevOps using Workload Identity Federation
        (also called federated credentials or OIDC federation).

        Workload Identity Federation lets an external identity provider (GitHub Actions, Kubernetes /
        AKS, Azure DevOps Pipelines, or any OIDC-compliant system) issue a short-lived JWT that is
        exchanged for an Azure AD access token — with NO client secret or certificate required on the
        Azure AD app registration.

        Three token sources are supported:

          1. File-based   — the federated token is read from a file path at runtime.
                           Used with Kubernetes / AKS Workload Identity, which projects and
                           periodically rotates a service-account token file into every pod.

          2. GitHub Actions OIDC — a fresh OIDC token is requested directly from the GitHub Actions
                           runtime endpoint (ACTIONS_ID_TOKEN_REQUEST_URL + ACTIONS_ID_TOKEN_REQUEST_TOKEN).
                           No extra tooling required; both environment variables are set automatically
                           by GitHub when the job has `id-token: write` permission.

          3. Manual token — the caller has already obtained a federated JWT from another source
                           (e.g. an Azure DevOps Pipelines OIDC task, a custom OIDC client) and
                           passes it in directly as a SecureString. This token cannot be refreshed
                           automatically; call New-AzDoAuthenticationProvider again with a new token
                           when it expires.

        Prerequisites:
          - An Azure AD App Registration with a federated identity credential configured for the
            appropriate issuer and subject (e.g. the GitHub Actions workflow, the AKS OIDC issuer,
            or the Azure DevOps project).
          - The Service Principal must be added to the Azure DevOps organisation with the required
            permissions via Access Control.

        Required values:
          TenantId           - The Azure AD tenant (directory) ID.
          ClientId           - The Application (client) ID of the App Registration.
          FederatedTokenFile - (File mode) Absolute path to the projected token file.
          FederatedToken     - (Manual mode) The federated JWT as a SecureString.
#>

# ── 1. File-based federated token (Kubernetes / AKS Workload Identity) ───────────────────────────
# AKS projects the service-account token at a well-known path set by the AZURE_FEDERATED_TOKEN_FILE
# environment variable. Use that variable (or hard-code the path) as FederatedTokenFile.
New-AzDoAuthenticationProvider `
    -OrganizationName    'my-organization' `
    -TenantId            '00000000-0000-0000-0000-000000000000' `
    -ClientId            'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee' `
    -FederatedTokenFile  $ENV:AZURE_FEDERATED_TOKEN_FILE    # set automatically in AKS pods

# Hard-coded file path variant
New-AzDoAuthenticationProvider `
    -OrganizationName    'my-organization' `
    -TenantId            '00000000-0000-0000-0000-000000000000' `
    -ClientId            'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee' `
    -FederatedTokenFile  '/var/run/secrets/azure/tokens/azure-identity-token'

# ── 2. GitHub Actions OIDC ────────────────────────────────────────────────────────────────────────
# The workflow must grant `id-token: write` permission at the job or workflow level.
# The ACTIONS_ID_TOKEN_REQUEST_URL and ACTIONS_ID_TOKEN_REQUEST_TOKEN environment variables are
# injected automatically by GitHub Actions when that permission is present.
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

# Custom audience (must match the federatedIdentityCredential audience in Azure AD)
New-AzDoAuthenticationProvider `
    -OrganizationName       'my-organization' `
    -TenantId               '00000000-0000-0000-0000-000000000000' `
    -ClientId               'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee' `
    -useGitHubActionsOIDC `
    -GitHubActionsAudience  'api://AzureADTokenExchange'

# ── 3. Manually-supplied federated token ─────────────────────────────────────────────────────────
# Use when the OIDC token has already been acquired by an external step (e.g. an Azure DevOps
# Pipelines OIDC service connection task) and is available as a variable.
$FederatedJWT = $ENV:SYSTEM_OIDCTOKEN | ConvertTo-SecureString -AsPlainText -Force  # ADO Pipelines

New-AzDoAuthenticationProvider `
    -OrganizationName  'my-organization' `
    -TenantId          '00000000-0000-0000-0000-000000000000' `
    -ClientId          'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee' `
    -FederatedToken    $FederatedJWT

# ── Skip connectivity verification (any mode) ────────────────────────────────────────────────────
New-AzDoAuthenticationProvider `
    -OrganizationName    'my-organization' `
    -TenantId            '00000000-0000-0000-0000-000000000000' `
    -ClientId            'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee' `
    -FederatedTokenFile  '/var/run/secrets/azure/tokens/azure-identity-token' `
    -NoVerify
