<#
.SYNOPSIS
    Represents a Service Principal token used for authentication via OAuth 2.0 client credentials.

.DESCRIPTION
    The ServicePrincipalToken class inherits from AuthenticationToken and stores an Azure AD
    OAuth 2.0 Bearer token obtained using client credentials (TenantId, ClientId, ClientSecret).
    It also stores the credentials required to refresh the token when it expires.

.NOTES
    The clientSecret is stored as a SecureString. GetClientSecret() returns it in plain text only
    while Update-AzServicePrincipal is on the call stack. That is a guard against accidental use,
    not a security boundary - see the comment above GetClientSecret().
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
        # 10-second clock skew buffer, same as ManagedIdentityToken. expires_on is UTC, so it
        # must be compared against UTC "now" - comparing against local (Get-Date) compares raw
        # ticks without adjusting for timezone offset, making tokens look expired early on
        # non-UTC machines.
        return ($this.expires_on.AddSeconds(-10) -lt [DateTime]::UtcNow)
    }

    <#
        Guard against *accidental* use of the client secret outside the token refresh path:
        GetClientSecret() returns plain text only while Update-AzServicePrincipal is on the call
        stack, so a resource function or a test cannot pull the secret into a log or a return
        value by mistake.

        It is NOT a security boundary. Any code in the same process can define a function named
        Update-AzServicePrincipal and call this from inside it, or read the hidden clientSecret
        SecureString directly and decode it. See AuthenticationToken.TestCaller() for the same
        point about the access token.
    #>
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
Function New-ServicePrincipalToken (
    [PSCustomObject]$TokenObj,
    [String]$TenantId,
    [String]$ClientId,
    [SecureString]$ClientSecret
)
{
    Write-Verbose "[ServicePrincipalToken] Creating a new ServicePrincipalToken object."
    return [ServicePrincipalToken]::New($TokenObj, $TenantId, $ClientId, $ClientSecret)
}
