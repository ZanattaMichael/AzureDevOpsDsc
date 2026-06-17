<#
.SYNOPSIS
Obtains a managed identity token from Azure AD.

.DESCRIPTION
The Get-AzManagedIdentityToken function is used to obtain an access token from Azure AD using a managed identity. It can only be called from the New-AzDoAuthenticationProvider or Update-AzManagedIdentity functions.

.PARAMETER OrganizationName
Specifies the name of the organization.

.PARAMETER Verify
Specifies whether to verify the connection. If this switch is not set, the function returns the managed identity token. If the switch is set, the function tests the connection and returns the access token.

.EXAMPLE
Get-AzManagedIdentityToken -OrganizationName "Contoso" -Verify
Obtains the access token for the managed identity associated with the organization "Contoso" and verifies the connection.

.NOTES
This function does not require the Azure PowerShell module.
#>

Function Get-AzManagedIdentityToken
{
    [CmdletBinding()]
    param (
        # Organization Name
        [Parameter(Mandatory = $true)]
        [String]
        $OrganizationName,

        # Verify the Connection
        [Parameter()]
        [Switch]
        $Verify
    )

    Write-Verbose "[Get-AzManagedIdentityToken] Getting the managed identity token for the organization $OrganizationName."

    # Check for a valid cached token before attempting IMDS.
    # Re-fetching via IMDS requires Azure Arc secret-file access, which needs admin rights.
    if ($ENV:AZDODSC_CACHE_DIRECTORY)
    {
        $cachedSettingsPath = Join-Path -Path $ENV:AZDODSC_CACHE_DIRECTORY -ChildPath 'ModuleSettings.clixml'
        if (Test-Path -LiteralPath $cachedSettingsPath)
        {
            try
            {
                $cachedSettings = Import-Clixml -LiteralPath $cachedSettingsPath -ErrorAction Stop
                $cachedToken    = $cachedSettings.Token
                $isMI = ($cachedToken.tokenType.ToString() -eq 'ManagedIdentity' -or [int]$cachedToken.tokenType -eq 0)
                if ($cachedToken -and $isMI -and $cachedToken.access_token -and
                    $cachedToken.expires_on -gt (Get-Date).AddSeconds(60))
                {
                    Write-Verbose "[Get-AzManagedIdentityToken] Reusing valid cached managed identity token (expires $($cachedToken.expires_on))."
                    $epochStart    = [datetime]::new(1970, 1, 1, 0, 0, 0, [DateTimeKind]::Utc)
                    $expiresOnUnix = [long]($cachedToken.expires_on.ToUniversalTime() - $epochStart).TotalSeconds
                    $bstr          = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($cachedToken.access_token)
                    $plainToken    = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
                    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
                    $tokenData = [PSCustomObject]@{
                        access_token = $plainToken
                        expires_on   = $expiresOnUnix
                        expires_in   = [int]$cachedToken.expires_in
                        resource     = [string]$cachedToken.resource
                        token_type   = [string]$cachedToken.token_type
                    }
                    $ManagedIdentity = New-ManagedIdentityToken $tokenData
                    if (-not $Verify -or (Test-AzToken $ManagedIdentity))
                    {
                        return $ManagedIdentity
                    }
                    Write-Verbose "[Get-AzManagedIdentityToken] Cached token failed verification — fetching a fresh token."
                }
            }
            catch { Write-Verbose "[Get-AzManagedIdentityToken] Could not reuse cached token: $_" }
        }
    }

    # Import the parameters
    $ManagedIdentityParams = @{
        # Define the Azure instance metadata endpoint to get the access token
        Uri = "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=499b84ac-1321-427f-aa17-267ca6975798"
        Method = 'Get'
        Headers = @{ Metadata="true" }
        ContentType = 'Application/json'
        NoAuthentication = $true
    }

    # Dertimine if the machine is an arc machine
    if ($env:IDENTITY_ENDPOINT)
    {

        $OSInfo = Get-OperatingSystemInfo

        # Test if console is being run as Administrator — emit a warning but allow
        # the request to proceed; Azure Arc IMDS security is enforced via the
        # WWW-Authenticate secret-file challenge, not solely by process elevation.
        if ($OSInfo.Windows)
        {
            if (-not(Test-isWindowsAdmin)) {
                Write-Warning "[Get-AzManagedIdentityToken] Not running as Administrator. Azure Arc authentication may fail if the secret file is not accessible."
            }
        }

        Write-Verbose "[Get-AzManagedIdentityToken] The machine is an Azure Arc machine. The Uri needs to be updated to $($env:IDENTITY_ENDPOINT):"
        $ManagedIdentityParams.Uri = '{0}?api-version=2020-06-01&resource=499b84ac-1321-427f-aa17-267ca6975798' -f $env:IDENTITY_ENDPOINT
        $ManagedIdentityParams.AzureArcAuthentication = $true

    }
    else
    {
        Write-Verbose "[Get-AzManagedIdentityToken] The machine is not an Azure Arc machine. No changes are required."
    }

    # Obtain the access token from Azure AD using the Managed Identity
    Write-Verbose "[Get-AzManagedIdentityToken] Invoking the Azure Instance Metadata Service to get the access token."

    # Invoke the RestAPI
    try
    {
        $response = Invoke-AzDevOpsApiRestMethod @ManagedIdentityParams
    }
    catch
    {
        # If there is an error it could be because it's an arc machine, and we need to use the secret file:
        $wwwAuthHeader = $_.Exception.Response.Headers.WwwAuthenticate
        if ($wwwAuthHeader -notmatch "Basic realm=.+")
        {
            Throw ('[Get-AzManagedIdentityToken] {0}' -f $_)
        }

        Write-Verbose "[Get-AzManagedIdentityToken] Managed Identity Token Retrival Failed. Retrying with secret file."

        # Extract the secret file path from the WWW-Authenticate header
        $secretFile = ($wwwAuthHeader -split "Basic realm=")[1]
        # Read the secret file to get the token
        $token = Get-Content -LiteralPath $secretFile -Raw
        # Add the token to the headers
        $ManagedIdentityParams.Headers.Authorization = "Basic $token"

        # Retry the request. Silently continue to suppress the error message, since we will handle it below.
        $response = Invoke-AzDevOpsApiRestMethod @ManagedIdentityParams -ErrorAction SilentlyContinue
    }

    # Test the response
    if ($null -eq $response.access_token)
    {
        throw "Error. Access token not returned from Azure Instance Metadata Service. Please ensure that the Azure Instance Metadata Service is available."
    }

    Write-Verbose "[Get-AzManagedIdentityToken] Managed Identity Token Retrival Successful."

    # TypeCast the response to a ManagedIdentityToken object
    $ManagedIdentity = New-ManagedIdentityToken $response
    # Null the response
    $null = $response

    # Return the token if the verify switch is not set
    if (-not($verify))
    {
        return $ManagedIdentity
    }

    Write-Verbose "[Get-AzManagedIdentityToken] Verifying the connection to the Azure DevOps API."

    # Test the Connection
    if (-not(Test-AzToken $ManagedIdentity))
    {
        throw "Error. Failed to call the Azure DevOps API."
    }

    Write-Verbose "[Get-AzManagedIdentityToken] Connection Verified."

    # Return the AccessToken
    return ($ManagedIdentity)

}
