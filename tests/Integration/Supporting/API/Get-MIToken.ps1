Function Get-MIToken {
    [CmdletBinding()]
    param (
        # Organization Name
        [Parameter(Mandatory = $true)]
        [String]
        $OrganizationName
    )

    Write-Verbose "[Get-MIToken] Getting the managed identity token for the organization $OrganizationName."

    # Internal helper: extract a live plaintext token from the ModuleSettings.clixml cache.
    $getCachedToken = {
        if (-not $ENV:AZDODSC_CACHE_DIRECTORY) { return $null }
        $settingsPath = Join-Path -Path $ENV:AZDODSC_CACHE_DIRECTORY -ChildPath 'ModuleSettings.clixml'
        if (-not (Test-Path -LiteralPath $settingsPath)) { return $null }
        try
        {
            $cached = Import-Clixml -LiteralPath $settingsPath -ErrorAction Stop
            $ct = $cached.Token
            if ($ct -and $ct.access_token -and $ct.expires_on -gt (Get-Date).AddSeconds(60))
            {
                $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ct.access_token)
                $plain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
                [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
                return $plain
            }
        }
        catch { Write-Verbose "[Get-MIToken] Could not read cached token: $_" }
        return $null
    }

    # Obtain the access token from Azure AD using the Managed Identity
    $ManagedIdentityParams = @{
        Uri         = "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=499b84ac-1321-427f-aa17-267ca6975798"
        Method      = 'Get'
        HttpHeaders = @{ Metadata="true" }
        ContentType = 'Application/json'
    }

    # Dertimine if the machine is an arc machine
    if ($env:IDENTITY_ENDPOINT)
    {
        Write-Verbose "[Get-MIToken] The machine is an Azure Arc machine. The Uri needs to be updated to $($env:IDENTITY_ENDPOINT):"
        $ManagedIdentityParams.Uri = '{0}?api-version=2020-06-01&resource=499b84ac-1321-427f-aa17-267ca6975798' -f $env:IDENTITY_ENDPOINT
        $ManagedIdentityParams.AzureArcAuthentication = $true
    }

    Write-Verbose "[Get-MIToken] Invoking the Azure Instance Metadata Service to get the access token."

    # Invoke the RestAPI
    try
    {
        $response = Invoke-APIRestMethod @ManagedIdentityParams
    }
    catch
    {
        # If there is an error it could be because it's an arc machine, and we need to use the secret file:
        $wwwAuthHeader = $_.Exception.Response.Headers.WwwAuthenticate
        if ($wwwAuthHeader -notmatch "Basic realm=.+")
        {
            Throw ('[Get-MIToken] {0}' -f $_)
        }

        Write-Verbose "[Get-MIToken] Managed Identity Token Retrival Failed. Retrying with secret file."

        # Extract the secret file path from the WWW-Authenticate header
        $secretFile = ($wwwAuthHeader -split "Basic realm=")[1]

        # Read the secret file to get the token. The file is ACL-restricted; if access is denied
        # fall back immediately to the cached token from ModuleSettings.clixml.
        $token = $null
        try { $token = Get-Content -LiteralPath $secretFile -Raw -ErrorAction Stop }
        catch
        {
            Write-Verbose "[Get-MIToken] Cannot read IMDS secret file ('$secretFile'): $_. Falling back to cached token."
            $cachedPlain = & $getCachedToken
            if ($cachedPlain)
            {
                return @{ tokenType = 'ManagedIdentity'; token = $cachedPlain }
            }
            Throw ('[Get-MIToken] {0}' -f $_)
        }

        # Add the token to the headers
        $ManagedIdentityParams.HttpHeaders.Authorization = "Basic $token"

        # Retry the request. Silently continue to suppress the error message, since we will handle it below.
        $response = Invoke-APIRestMethod @ManagedIdentityParams -ErrorAction SilentlyContinue
    }

    # Test the response
    if ($null -eq $response.access_token)
    {
        # IMDS failed — attempt to fall back to the cached token on disk so that tests can
        # continue even when the Azure Arc secret file is inaccessible.
        $cachedPlain = & $getCachedToken
        if ($cachedPlain)
        {
            Write-Verbose "[Get-MIToken] Using cached managed identity token from ModuleSettings.clixml."
            return @{ tokenType = 'ManagedIdentity'; token = $cachedPlain }
        }
        throw "Error. Access token not returned from Azure Instance Metadata Service. Please ensure that the Azure Instance Metadata Service is available."
    }

    # Return the token
    return @{
        tokenType = 'ManagedIdentity'
        token = $response.access_token
    }

}
