<#
.SYNOPSIS
    Builds a signed JWT client assertion for OAuth 2.0 certificate-based authentication.

.DESCRIPTION
    Constructs a JWT with RS256 signing using the provided X.509 certificate. The resulting
    JWT is suitable for use as the client_assertion in an OAuth 2.0 token request.

.PARAMETER Certificate
    An X509Certificate2 object with an accessible private key (RSA).

.PARAMETER TenantId
    Azure AD tenant ID, used to construct the audience claim.

.PARAMETER ClientId
    Application (client) ID, used as the issuer and subject claims.
#>
Function Build-JWTAssertion
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

        [Parameter(Mandatory = $true)]
        [String]$TenantId,

        [Parameter(Mandatory = $true)]
        [String]$ClientId
    )

    # Helper: Base64Url encode without padding
    function ConvertTo-Base64UrlEncoding ([byte[]]$bytes)
    {
        return [Convert]::ToBase64String($bytes).TrimEnd('=').Replace('+', '-').Replace('/', '_')
    }

    # Build x5t (SHA-1 thumbprint as base64url)
    $thumbprintBytes = [byte[]] -split ($Certificate.Thumbprint -replace '..', '0x$& ')
    $x5t = ConvertTo-Base64UrlEncoding $thumbprintBytes

    # JWT header
    $headerObj = [ordered]@{
        alg = 'RS256'
        typ = 'JWT'
        x5t = $x5t
    }
    $headerJson  = $headerObj | ConvertTo-Json -Compress
    $headerB64   = ConvertTo-Base64UrlEncoding ([System.Text.Encoding]::UTF8.GetBytes($headerJson))

    # JWT payload
    $now        = [DateTimeOffset]::UtcNow
    $expSeconds = $now.AddMinutes(10).ToUnixTimeSeconds()
    $nbfSeconds = $now.ToUnixTimeSeconds()
    $audience   = "https://login.microsoftonline.com/$TenantId/oauth2/token"

    $payloadObj = [ordered]@{
        iss = $ClientId
        sub = $ClientId
        aud = $audience
        exp = $expSeconds
        nbf = $nbfSeconds
        jti = [Guid]::NewGuid().ToString()
    }
    $payloadJson = $payloadObj | ConvertTo-Json -Compress
    $payloadB64  = ConvertTo-Base64UrlEncoding ([System.Text.Encoding]::UTF8.GetBytes($payloadJson))

    # Data to sign
    $signingInput = "$headerB64.$payloadB64"
    $signingBytes = [System.Text.Encoding]::UTF8.GetBytes($signingInput)

    # Sign with RSA SHA-256 using the certificate private key
    $rsa = $Certificate.GetRSAPrivateKey()
    if ($null -eq $rsa)
    {
        throw "[Build-JWTAssertion] Certificate does not have an accessible RSA private key."
    }

    $signatureBytes = $rsa.SignData($signingBytes, [System.Security.Cryptography.HashAlgorithmName]::SHA256, [System.Security.Cryptography.RSASignaturePadding]::Pkcs1)
    $signatureB64   = ConvertTo-Base64UrlEncoding $signatureBytes

    return "$signingInput.$signatureB64"
}
