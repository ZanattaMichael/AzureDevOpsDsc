<#
.SYNOPSIS
    Represents a Service Principal Certificate token used for OAuth 2.0 JWT assertion authentication.

.DESCRIPTION
    The CertificateToken class inherits from AuthenticationToken and stores an Azure AD Bearer token
    obtained using a certificate-based client assertion (JWT signed with an X.509 private key).
    Credentials (thumbprint or file path) are stored to enable token refresh.

.NOTES
    Supports two credential modes:
      - Windows cert store: provide CertificateThumbprint
      - PFX file (cross-platform): provide CertificatePath + CertificatePassword
#>
class CertificateToken : AuthenticationToken
{
    [DateTime]$expires_on
    [Int]$expires_in
    [String]$resource
    [String]$token_type
    [String]$tenantId
    [String]$clientId
    [String]$certificateThumbprint
    [String]$certificatePath
    hidden [SecureString]$certificatePassword

    # Constructor: cert store thumbprint
    CertificateToken([PSCustomObject]$TokenObj, [String]$TenantId, [String]$ClientId, [String]$CertThumbprint)
    {
        $this.tokenType = [TokenType]::Certificate

        if (-not $this.isValid($TokenObj))
        {
            throw "[CertificateToken] The TokenObj is not valid. Required properties: access_token, expires_on, expires_in, resource, token_type."
        }

        $epochStart = [datetime]::new(1970, 1, 1, 0, 0, 0, [DateTimeKind]::Utc)

        $this.access_token            = $TokenObj.access_token | ConvertTo-SecureString -AsPlainText -Force
        $this.expires_on              = $epochStart.AddSeconds($TokenObj.expires_on)
        $this.expires_in              = $TokenObj.expires_in
        $this.resource                = $TokenObj.resource
        $this.token_type              = $TokenObj.token_type
        $this.tenantId                = $TenantId
        $this.clientId                = $ClientId
        $this.certificateThumbprint   = $CertThumbprint
        $this.certificatePath         = ''
    }

    # Constructor: PFX file path + password
    CertificateToken([PSCustomObject]$TokenObj, [String]$TenantId, [String]$ClientId, [String]$CertPath, [SecureString]$CertPassword)
    {
        $this.tokenType = [TokenType]::Certificate

        if (-not $this.isValid($TokenObj))
        {
            throw "[CertificateToken] The TokenObj is not valid. Required properties: access_token, expires_on, expires_in, resource, token_type."
        }

        $epochStart = [datetime]::new(1970, 1, 1, 0, 0, 0, [DateTimeKind]::Utc)

        $this.access_token            = $TokenObj.access_token | ConvertTo-SecureString -AsPlainText -Force
        $this.expires_on              = $epochStart.AddSeconds($TokenObj.expires_on)
        $this.expires_in              = $TokenObj.expires_in
        $this.resource                = $TokenObj.resource
        $this.token_type              = $TokenObj.token_type
        $this.tenantId                = $TenantId
        $this.clientId                = $ClientId
        $this.certificateThumbprint   = ''
        $this.certificatePath         = $CertPath
        $this.certificatePassword     = $CertPassword
    }

    hidden [Bool] isValid([PSCustomObject]$TokenObj)
    {
        $requiredKeys = @('access_token', 'expires_on', 'expires_in', 'resource', 'token_type')
        foreach ($key in $requiredKeys)
        {
            if (-not $TokenObj."$key")
            {
                Write-Verbose "[CertificateToken] Missing required property: $key"
                return $false
            }
        }
        return $true
    }

    [Bool] isExpired()
    {
        return ($this.expires_on.AddSeconds(-10) -lt (Get-Date))
    }

    [String] Get()
    {
        Write-Verbose "[CertificateToken] Getting the access token."
        $this.TestCaller()
        Write-Verbose "[CertificateToken] Token retrieval successful."
        return ($this.ConvertFromSecureString($this.access_token))
    }
}

<#
.SYNOPSIS
    Creates a new CertificateToken using a Windows certificate store thumbprint.
#>
Function global:New-CertificateToken (
    [PSCustomObject]$TokenObj,
    [String]$TenantId,
    [String]$ClientId,
    [String]$Thumbprint
)
{
    Write-Verbose "[CertificateToken] Creating a new CertificateToken object (thumbprint)."
    return [CertificateToken]::New($TokenObj, $TenantId, $ClientId, $Thumbprint)
}

<#
.SYNOPSIS
    Creates a new CertificateToken using a PFX certificate file.
#>
Function global:New-CertificateTokenFromFile (
    [PSCustomObject]$TokenObj,
    [String]$TenantId,
    [String]$ClientId,
    [String]$CertPath,
    [SecureString]$CertPassword
)
{
    Write-Verbose "[CertificateToken] Creating a new CertificateToken object (file)."
    return [CertificateToken]::New($TokenObj, $TenantId, $ClientId, $CertPath, $CertPassword)
}
