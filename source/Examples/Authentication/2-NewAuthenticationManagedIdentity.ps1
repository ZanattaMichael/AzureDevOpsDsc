<#
    .DESCRIPTION
        This example shows how to authenticate with Azure DevOps using an Azure Managed Identity.

        Managed Identity authentication is the recommended approach when running DSC configurations
        on Azure resources such as Virtual Machines, Azure Arc-enabled servers, or Azure Automation.
        No credentials or secrets need to be stored — the identity is provided by the Azure platform.

        Prerequisites:
          - The hosting resource must have a System-assigned or User-assigned Managed Identity enabled.
          - The Managed Identity must be added to the Azure DevOps organisation with appropriate permissions.
#>

# Authenticate using the Managed Identity assigned to the current Azure resource
New-AzDoAuthenticationProvider -OrganizationName 'my-organization' -useManagedIdentity

# Skip the initial connectivity verification check
New-AzDoAuthenticationProvider -OrganizationName 'my-organization' -useManagedIdentity -NoVerify
