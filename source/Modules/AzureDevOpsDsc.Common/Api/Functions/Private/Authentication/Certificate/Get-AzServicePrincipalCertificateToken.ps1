<#
.SYNOPSIS
    Acquires an Azure DevOps Bearer token using a Service Principal certificate assertion.

.DESCRIPTION
    Posts a signed JWT assertion to the Azure AD token endpoint to obtain a Bearer token
    scoped to the Azure DevOps resource. Supports both Windows certificate store thumbprint
    and cross-platform PFX file loading.

.PARAMETER OrganizationName
    Azure DevOps organization name, used when verifying the token.

.PARAMETER TenantId
    Azure AD tenant ID.

.PARAMETER ClientId
    Application (client) ID of the service principal.

.PARAMETER CertificateThumbprint
    SHA-1 thumbprint of the certificate in the current user or local machine cert store.

.PARAMETER CertificatePath
    Path to a .pfx certificate file. Used for cross-platform scenarios.

.PARAMETER CertificatePassword
    Password protecting the PFX file, as a SecureString.

.PARAMETER Verify
    If set, verifies the token by calling the Azure DevOps API.
#>
Function Get-AzServicePrincipalCertificateToken
{
    [CmdletBinding(DefaultParameterSetName = 'Thumbprint')]
    param (
        [Parameter(Mandatory = $true)]
        [String]$OrganizationName,

        [Parameter(Mandatory = $true)]
        [String]$TenantId,

        [Parameter(Mandatory = $true)]
        [String]$ClientId,

        [Parameter(Mandatory = $true, ParameterSetName = 'Thumbprint')]
        [String]$CertificateThumbprint,

        [Parameter(Mandatory = $true, ParameterSetName = 'File')]
        [String]$CertificatePath,

        [Parameter(Mandatory = $true, ParameterSetName = 'File')]
        [SecureString]$CertificatePassword,

        [Parameter()]
        [Switch]$Verify
    )

    Write-Verbose "[Get-AzServicePrincipalCertificateToken] Acquiring certificate-based token for tenant '$TenantId', client '$ClientId'."

    # Load the certificate
    if ($PSCmdlet.ParameterSetName -eq 'Thumbprint')
    {
        Write-Verbose "[Get-AzServicePrincipalCertificateToken] Loading certificate from store with thumbprint '$CertificateThumbprint'."

        $cert = Get-Item "Cert:\CurrentUser\My\$CertificateThumbprint" -ErrorAction SilentlyContinue
        if ($null -eq $cert)
        {
            $cert = Get-Item "Cert:\LocalMachine\My\$CertificateThumbprint" -ErrorAction SilentlyContinue
        }
        if ($null -eq $cert)
        {
            throw "[Get-AzServicePrincipalCertificateToken] Certificate with thumbprint '$CertificateThumbprint' not found in CurrentUser\My or LocalMachine\My."
        }
    }
    else
    {
        Write-Verbose "[Get-AzServicePrincipalCertificateToken] Loading certificate from file '$CertificatePath'."

        if (-not (Test-Path -Path $CertificatePath))
        {
            throw "[Get-AzServicePrincipalCertificateToken] Certificate file not found at path '$CertificatePath'."
        }

        $BSTR           = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($CertificatePassword)
        $plainPassword  = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)

        $cert = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new(
            $CertificatePath,
            $plainPassword,
            [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::EphemeralKeySet
        )
    }

    # Build JWT assertion
    $jwtAssertion = Build-JWTAssertion -Certificate $cert -TenantId $TenantId -ClientId $ClientId

    $tokenEndpoint = "https://login.microsoftonline.com/$TenantId/oauth2/token"
    $body = "grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer" +
            "&client_id=$([Uri]::EscapeDataString($ClientId))" +
            "&client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer" +
            "&client_assertion=$([Uri]::EscapeDataString($jwtAssertion))" +
            "&resource=499b84ac-1321-427f-aa17-267ca6975798"

    try
    {
        $response = Invoke-RestMethod -Uri $tokenEndpoint -Method Post -Body $body -ContentType 'application/x-www-form-urlencoded'
    }
    catch
    {
        throw "[Get-AzServicePrincipalCertificateToken] Failed to acquire token from '$tokenEndpoint'. Error: $_"
    }

    if ([String]::IsNullOrEmpty($response.access_token))
    {
        throw "[Get-AzServicePrincipalCertificateToken] Access token not returned. Verify TenantId, ClientId, and certificate configuration."
    }

    Write-Verbose "[Get-AzServicePrincipalCertificateToken] Token acquired successfully."

    if ($PSCmdlet.ParameterSetName -eq 'Thumbprint')
    {
        $token = New-CertificateToken -TokenObj $response -TenantId $TenantId -ClientId $ClientId -Thumbprint $CertificateThumbprint
    }
    else
    {
        $token = New-CertificateTokenFromFile -TokenObj $response -TenantId $TenantId -ClientId $ClientId -CertPath $CertificatePath -CertPassword $CertificatePassword
    }

    if (-not $Verify)
    {
        return $token
    }

    Write-Verbose "[Get-AzServicePrincipalCertificateToken] Verifying the connection to the Azure DevOps API."

    if (-not (Test-AzToken $token))
    {
        throw "[Get-AzServicePrincipalCertificateToken] Token verification failed. Unable to connect to Azure DevOps organization '$OrganizationName'."
    }

    Write-Verbose "[Get-AzServicePrincipalCertificateToken] Token verified successfully."
    return $token
}
