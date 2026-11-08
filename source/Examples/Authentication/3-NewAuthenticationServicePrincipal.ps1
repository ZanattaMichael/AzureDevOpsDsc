<#
    .DESCRIPTION
        This example shows how to authenticate with Azure DevOps using an Azure AD Service Principal
        with a Client Secret (OAuth 2.0 client credentials flow).

        Use this approach when running DSC configurations from non-Azure environments (e.g. on-premises
        servers, pipelines without Managed Identity support) where you have registered an Azure AD
        application and granted it access to the Azure DevOps organisation.

        Prerequisites:
          - An Azure AD App Registration with a Client Secret.
          - The Service Principal (Enterprise Application) must be added to the Azure DevOps organisation
            with appropriate permissions via Access Control.

        Required values:
          TenantId     - The Azure AD tenant (directory) ID, e.g. '00000000-0000-0000-0000-000000000000'
          ClientId     - The Application (client) ID of the App Registration.
          ClientSecret - The client secret value generated in the App Registration, as a SecureString.

        Always pass the client secret as a SecureString. A plain-text -ClientSecret still works but
        lands in shell history, transcripts and process listings, and the module warns when it is used.
#>

# Interactive use: prompt for the secret so it never appears in the script or the shell history
$SecureSecret = Read-Host -Prompt 'Enter client secret' -AsSecureString
New-AzDoAuthenticationProvider `
    -OrganizationName           'my-organization' `
    -TenantId                   '00000000-0000-0000-0000-000000000000' `
    -ClientId                   'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee' `
    -SecureStringClientSecret   $SecureSecret

# Automation: read the secret from a secret store (a pipeline secret variable, Azure Key Vault,
# SecretManagement, ...) and convert it in memory, rather than hard-coding it
$SecureSecret = ConvertTo-SecureString -String $env:AZDO_CLIENT_SECRET -AsPlainText -Force
New-AzDoAuthenticationProvider `
    -OrganizationName           'my-organization' `
    -TenantId                   '00000000-0000-0000-0000-000000000000' `
    -ClientId                   'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee' `
    -SecureStringClientSecret   $SecureSecret

# Skip the initial connectivity verification check
New-AzDoAuthenticationProvider `
    -OrganizationName           'my-organization' `
    -TenantId                   '00000000-0000-0000-0000-000000000000' `
    -ClientId                   'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee' `
    -SecureStringClientSecret   $SecureSecret `
    -NoVerify
