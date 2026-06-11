<#
.SYNOPSIS
Adds the appropriate authentication HTTP header based on the type of authentication token.

.DESCRIPTION
The Add-AuthenticationHTTPHeader function determines the type of authentication token and adds the corresponding HTTP header.
It supports Personal Access Tokens and Managed Identity Tokens. If the token is null or the token type is not supported, an error is thrown.

.PARAMETER None
This function does not take any parameters.

.OUTPUTS
String
Returns the authentication HTTP header as a string.

.NOTES
The function relies on the global variables $Global:DSCAZDO_AuthenticationToken and $Global:DSCAZDO_OrganizationName.

.EXAMPLE
$header = Add-AuthenticationHTTPHeader
# Adds the appropriate authentication HTTP header and returns it as a string.
#>

Function Add-AuthenticationHTTPHeader
{
    # If the global token is null, attempt to restore from clixml cache.
    # This handles the DSC isolated-runspace scenario where Construct() sets globals in the
    # constructor runspace but the method (Set/Test/Get) executes in the calling runspace.
    if ($null -eq $Global:DSCAZDO_AuthenticationToken)
    {
        Write-Verbose "[Add-AuthenticationHTTPHeader] Authentication token is null. Attempting to restore from cache."
        if ($ENV:AZDODSC_CACHE_DIRECTORY)
        {
            $settingsPath = Join-Path -Path $ENV:AZDODSC_CACHE_DIRECTORY -ChildPath 'ModuleSettings.clixml'
            if (Test-Path -LiteralPath $settingsPath)
            {
                $objectSettings = Import-Clixml -LiteralPath $settingsPath
                $organizationName = $objectSettings.OrganizationName
                # tokenType is serialized as an integer enum value (0=ManagedIdentity, 1=PersonalAccessToken)
                $tokenType = $objectSettings.Token.tokenType
                try
                {
                    if ($tokenType -eq 'ManagedIdentity' -or $tokenType -eq 0)
                    {
                        # Reconstruct a live ManagedIdentityToken from the deserialized cached token.
                        # Avoid calling the IMDS endpoint (requires Azure Arc secret-file ACL access).
                        $ct            = $objectSettings.Token
                        $epochStart    = [datetime]::new(1970, 1, 1, 0, 0, 0, [DateTimeKind]::Utc)
                        $expiresOnUnix = [long]($ct.expires_on.ToUniversalTime() - $epochStart).TotalSeconds
                        $bstr          = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ct.access_token)
                        $plainToken    = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
                        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
                        $tokenData = [PSCustomObject]@{
                            access_token = $plainToken
                            expires_on   = $expiresOnUnix
                            expires_in   = [int]$ct.expires_in
                            resource     = [string]$ct.resource
                            token_type   = [string]$ct.token_type
                        }
                        $Global:DSCAZDO_AuthenticationToken = New-ManagedIdentityToken $tokenData
                        $Global:DSCAZDO_OrganizationName    = $organizationName
                    }
                    elseif ($tokenType -eq 'PersonalAccessToken' -or $tokenType -eq 1)
                    {
                        New-AzDoAuthenticationProvider -OrganizationName $organizationName -SecureStringPersonalAccessToken $objectSettings.Token.access_token -isResource -NoVerify
                    }
                }
                catch
                {
                    Write-Warning "[Add-AuthenticationHTTPHeader] Failed to restore authentication token from cache: $_"
                }
            }
        }
    }

    # Dertimine the type of token.
    $headerValue = ""
    switch ($Global:DSCAZDO_AuthenticationToken.tokenType)
    {

        # If the token is null
        {[String]::IsNullOrEmpty($_)} {
            throw "[Add-AuthenticationHTTPHeader] Error. The authentication token is null. Please ensure that the authentication token is set."
        }
        {$_ -eq 'PersonalAccessToken'} {
            # Personal Access Token

            # Add the Personal Access Token to the header
            $headerValue = 'Authorization: Basic {0}' -f $Global:DSCAZDO_AuthenticationToken.Get()
            break
        }
        {$_ -eq 'ManagedIdentity'} {
            # Managed Identity Token
            Write-Verbose "[Add-AuthenticationHTTPHeader] Adding Managed Identity Token to the HTTP Headers."

            # Test if the Managed Identity Token has expired
            if ($Global:DSCAZDO_AuthenticationToken.isExpired())
            {
                Write-Verbose "[Add-AuthenticationHTTPHeader] Managed Identity Token has expired. Obtaining a new token."
                # If so, get a new token
                $Global:DSCAZDO_AuthenticationToken = Update-AzManagedIdentity -OrganizationName $Global:DSCAZDO_OrganizationName
            }

            # Add the Managed Identity Token to the header
            $headerValue = 'Bearer {0}' -f $Global:DSCAZDO_AuthenticationToken.Get()
            break

        }
        default {
            throw "[Add-AuthenticationHTTPHeader] Error. The authentication token type is not supported."
        }

    }

    Write-Verbose "[Add-AuthenticationHTTPHeader] Adding Header"

    # Return the header value
    return $headerValue

}
