<#
.SYNOPSIS
    Represents a Service Principal token used for authentication via OAuth 2.0 client credentials.

.DESCRIPTION
    The ServicePrincipalToken class inherits from AuthenticationToken and stores an Azure AD
    OAuth 2.0 Bearer token obtained using client credentials (TenantId, ClientId, ClientSecret).
    It also stores the credentials required to refresh the token when it expires.

.NOTES
    The clientSecret is stored as a SecureString and can only be retrieved by Update-AzServicePrincipal
    via the GetClientSecret() method, which enforces call stack validation.
#>
class ServicePrincipalToken : AuthenticationToken
{
    [DateTime]$expires_on
    [Int]$expires_in
    [String]$resource
    [String]$token_type
    [String]$tenantId
    [String]$clientId
    hidden [SecureString]$clientSecret

    ServicePrincipalToken([PSCustomObject]$TokenObj, [String]$TenantId, [String]$ClientId, [SecureString]$ClientSecret)
    {
        $this.tokenType = [TokenType]::ServicePrincipal

        if (-not $this.isValid($TokenObj))
        {
            throw "[ServicePrincipalToken] The TokenObj is not valid. Required properties: access_token, expires_on, expires_in, resource, token_type."
        }

        $epochStart = [datetime]::new(1970, 1, 1, 0, 0, 0, [DateTimeKind]::Utc)

        $this.access_token  = $TokenObj.access_token | ConvertTo-SecureString -AsPlainText -Force
        $this.expires_on    = $epochStart.AddSeconds($TokenObj.expires_on)
        $this.expires_in    = $TokenObj.expires_in
        $this.resource      = $TokenObj.resource
        $this.token_type    = $TokenObj.token_type
        $this.tenantId      = $TenantId
        $this.clientId      = $ClientId
        $this.clientSecret  = $ClientSecret
    }

    hidden [Bool] isValid([PSCustomObject]$TokenObj)
    {
        $requiredKeys = @('access_token', 'expires_on', 'expires_in', 'resource', 'token_type')
        foreach ($key in $requiredKeys)
        {
            if (-not $TokenObj."$key")
            {
                Write-Verbose "[ServicePrincipalToken] Missing required property: $key"
                return $false
            }
        }
        return $true
    }

    [Bool] isExpired()
    {
        # 10-second clock skew buffer, same as ManagedIdentityToken
        return ($this.expires_on.AddSeconds(-10) -lt (Get-Date))
    }

    # Only callable from Update-AzServicePrincipal — enforced by call stack check
    [String] GetClientSecret()
    {
        if (-not ($this.TestCallStack('Update-AzServicePrincipal')))
        {
            throw "[ServicePrincipalToken][Access Denied] GetClientSecret() can only be called from Update-AzServicePrincipal."
        }
        return ($this.ConvertFromSecureString($this.clientSecret))
    }

    [String] Get()
    {
        Write-Verbose "[ServicePrincipalToken] Getting the access token."
        $this.TestCaller()
        Write-Verbose "[ServicePrincipalToken] Token retrieval successful."
        return ($this.ConvertFromSecureString($this.access_token))
    }
}

<#
.SYNOPSIS
    Creates a new ServicePrincipalToken object.

.PARAMETER TokenObj
    PSCustomObject containing the OAuth token response (access_token, expires_on, expires_in, resource, token_type).

.PARAMETER TenantId
    Azure AD tenant ID used to acquire the token.

.PARAMETER ClientId
    Application (client) ID of the service principal.

.PARAMETER ClientSecret
    Client secret as a SecureString, stored for token refresh.
#>
Function global:New-ServicePrincipalToken (
    [PSCustomObject]$TokenObj,
    [String]$TenantId,
    [String]$ClientId,
    [SecureString]$ClientSecret
)
{
    Write-Verbose "[ServicePrincipalToken] Creating a new ServicePrincipalToken object."
    return [ServicePrincipalToken]::New($TokenObj, $TenantId, $ClientId, $ClientSecret)
}
