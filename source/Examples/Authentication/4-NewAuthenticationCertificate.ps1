<#
    .DESCRIPTION
        This example shows how to authenticate with Azure DevOps using an Azure AD Service Principal
        with a Certificate (OAuth 2.0 JWT client assertion flow).

        Certificate-based authentication is more secure than client secrets because private keys
        never leave the machine and certificates can be stored in the Windows Certificate Store or
        as PFX files on any platform.

        Prerequisites:
          - An Azure AD App Registration with an uploaded certificate (public key).
          - The private key must be available on the machine running DSC (cert store or PFX file).
          - The Service Principal must be added to the Azure DevOps organisation with appropriate permissions.

        Required values:
          TenantId              - The Azure AD tenant (directory) ID.
          ClientId              - The Application (client) ID of the App Registration.
          CertificateThumbprint - (Windows cert store) Thumbprint of the certificate in Cert:\LocalMachine\My.
          CertificatePath       - (Cross-platform PFX) Absolute path to the .pfx file.
          CertificatePassword   - (Cross-platform PFX) Password protecting the .pfx file, as a SecureString.
#>

# ── Windows certificate store (thumbprint) ──────────────────────────────────────────────────────
# The certificate must be present in the local machine or current user certificate store.
New-AzDoAuthenticationProvider `
    -OrganizationName        'my-organization' `
    -TenantId                '00000000-0000-0000-0000-000000000000' `
    -ClientId                'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee' `
    -CertificateThumbprint   'AABBCCDDEEFF00112233445566778899AABBCCDD'

# ── PFX file (cross-platform — works on Linux and macOS as well as Windows) ──────────────────────
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
