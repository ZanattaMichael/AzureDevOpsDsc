<#
    .DESCRIPTION
        This example shows how to authenticate with Azure DevOps using Azure CLI delegated credentials.

        When you are already signed in to the Azure CLI (`az login`) on the machine running DSC,
        this method acquires a Bearer token from the CLI without requiring any additional credentials
        to be stored in your configuration. It is particularly useful for local development and
        interactive sessions.

        Prerequisites:
          - The Azure CLI must be installed and available in PATH.
          - You must be signed in: run `az login` (or `az login --use-device-code` in headless environments).
          - The signed-in account must have access to the Azure DevOps organisation.

        Note:
          The CLI token is scoped to the currently active Azure subscription/tenant. If you manage
          multiple tenants, ensure the correct account context is active before calling this function
          (`az account show` to verify, `az account set --subscription <id>` to switch).
#>

# Authenticate using the active Azure CLI session
New-AzDoAuthenticationProvider -OrganizationName 'my-organization' -useAzureCLI

# Skip the initial connectivity verification check
New-AzDoAuthenticationProvider -OrganizationName 'my-organization' -useAzureCLI -NoVerify
