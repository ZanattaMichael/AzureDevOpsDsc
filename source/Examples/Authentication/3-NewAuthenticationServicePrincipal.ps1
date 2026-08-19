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
          TenantId   - The Azure AD tenant (directory) ID, e.g. '00000000-0000-0000-0000-000000000000'
          ClientId   - The Application (client) ID of the App Registration.
          ClientSecret - The client secret value generated in the App Registration.
#>

# Plain-text client secret
New-AzDoAuthenticationProvider `
    -OrganizationName 'my-organization' `
    -TenantId         '00000000-0000-0000-0000-000000000000' `
    -ClientId         'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee' `
    -ClientSecret     'my-client-secret-value'

# SecureString client secret (preferred for production — avoids plain-text in memory)
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
