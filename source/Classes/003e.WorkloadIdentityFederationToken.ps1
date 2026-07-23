<#
.SYNOPSIS
    Represents a Workload Identity Federation token used for OAuth 2.0 JWT assertion authentication.

.DESCRIPTION
    The WorkloadIdentityFederationToken class inherits from AuthenticationToken and stores an
    Azure AD Bearer token obtained by exchanging a federated OIDC token (issued by an external
    identity provider such as Kubernetes/AKS, GitHub Actions, or Azure DevOps Pipelines) for an
    Azure AD access token via the JWT-bearer client assertion flow. No client secret or
    certificate is ever stored or required on the Azure AD app registration.

.NOTES
    Supports three federated-token sources, tracked via FederatedTokenSource so the token can be
    refreshed the same way it was originally acquired:
      - 'File'          : re-read the token from FederatedTokenFile (e.g. AKS/Kubernetes workload
                           identity, which projects and periodically rotates a token file).
      - 'GitHubActions'  : re-request a fresh ID token from the GitHub Actions OIDC endpoint.
      - 'Manual'         : a caller-supplied token cannot be refreshed by this class; the caller
                            (e.g. an Azure DevOps Pipelines OIDC step) must supply a fresh token
                            and call New-AzDoAuthenticationProvider again.
#>
class WorkloadIdentityFederationToken : AuthenticationToken
{
    [DateTime]$expires_on
    [Int]$expires_in
    [String]$resource
    [String]$token_type
    [String]$tenantId
    [String]$clientId
    [String]$federatedTokenSource
    [String]$federatedTokenFile

    WorkloadIdentityFederationToken([PSCustomObject]$TokenObj, [String]$TenantId, [String]$ClientId, [String]$FederatedTokenSource, [String]$FederatedTokenFile)
    {
        $this.tokenType = [TokenType]::WorkloadIdentityFederation

        if (-not $this.isValid($TokenObj))
        {
            throw "[WorkloadIdentityFederationToken] The TokenObj is not valid. Required properties: access_token, expires_on, expires_in, resource, token_type."
        }

        $epochStart = [datetime]::new(1970, 1, 1, 0, 0, 0, [DateTimeKind]::Utc)

        $this.access_token         = $TokenObj.access_token | ConvertTo-SecureString -AsPlainText -Force
        $this.expires_on           = $epochStart.AddSeconds($TokenObj.expires_on)
        $this.expires_in           = $TokenObj.expires_in
        $this.resource             = $TokenObj.resource
        $this.token_type           = $TokenObj.token_type
        $this.tenantId             = $TenantId
        $this.clientId             = $ClientId
        $this.federatedTokenSource = $FederatedTokenSource
        $this.federatedTokenFile   = $FederatedTokenFile
    }

    hidden [Bool] isValid([PSCustomObject]$TokenObj)
    {
        $requiredKeys = @('access_token', 'expires_on', 'expires_in', 'resource', 'token_type')
        foreach ($key in $requiredKeys)
        {
            if (-not $TokenObj."$key")
            {
                Write-Verbose "[WorkloadIdentityFederationToken] Missing required property: $key"
                return $false
            }
        }
        return $true
    }

    [Bool] isExpired()
    {
        # 10-second clock skew buffer, same as the other token classes. expires_on is UTC, so it
        # must be compared against UTC "now" - comparing against local (Get-Date) compares raw
        # ticks without adjusting for timezone offset, making tokens look expired early on
        # non-UTC machines.
        return ($this.expires_on.AddSeconds(-10) -lt [DateTime]::UtcNow)
    }

    [String] Get()
    {
        Write-Verbose "[WorkloadIdentityFederationToken] Getting the access token."
        $this.TestCaller()
        Write-Verbose "[WorkloadIdentityFederationToken] Token retrieval successful."
        return ($this.ConvertFromSecureString($this.access_token))
    }
}

<#
.SYNOPSIS
    Creates a new WorkloadIdentityFederationToken object.

.PARAMETER TokenObj
    PSCustomObject containing the OAuth token response (access_token, expires_on, expires_in, resource, token_type).

.PARAMETER TenantId
    Azure AD tenant ID.

.PARAMETER ClientId
    Application (client) ID of the service principal / federated identity.

.PARAMETER FederatedTokenSource
    How the federated assertion was obtained: 'File', 'GitHubActions', or 'Manual'. Used on refresh.

.PARAMETER FederatedTokenFile
    Path to the federated token file, only set (and only meaningful) when FederatedTokenSource is 'File'.
#>
Function global:New-WorkloadIdentityFederationToken (
    [PSCustomObject]$TokenObj,
    [String]$TenantId,
    [String]$ClientId,
    [String]$FederatedTokenSource,
    [String]$FederatedTokenFile
)
{
    Write-Verbose "[WorkloadIdentityFederationToken] Creating a new WorkloadIdentityFederationToken object."
    return [WorkloadIdentityFederationToken]::New($TokenObj, $TenantId, $ClientId, $FederatedTokenSource, $FederatedTokenFile)
}
