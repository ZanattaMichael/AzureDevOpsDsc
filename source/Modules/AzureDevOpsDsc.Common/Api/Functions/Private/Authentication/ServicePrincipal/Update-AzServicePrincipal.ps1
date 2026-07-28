<#
.SYNOPSIS
    Refreshes the service principal Bearer token when it has expired.

.DESCRIPTION
    Reads the TenantId, ClientId, and ClientSecret from the current global token object,
    re-acquires a fresh token via Get-AzServicePrincipalToken, and updates the global variable.
    Called automatically by Add-AuthenticationHTTPHeader when isExpired() returns true.
#>
Function Update-AzServicePrincipal
{
    if ($null -eq $Global:DSCAZDO_OrganizationName)
    {
        throw "[Update-AzServicePrincipal] Organization Name is not set. Please run 'New-AzDoAuthenticationProvider -OrganizationName <OrganizationName>'"
    }

    $currentToken = $Global:DSCAZDO_AuthenticationToken

    if ($null -eq $currentToken)
    {
        throw "[Update-AzServicePrincipal] No existing authentication token found. Cannot refresh."
    }

    # Retrieve stored credentials from the existing token
    $tenantId     = $currentToken.tenantId
    $clientId     = $currentToken.clientId
    $clientSecret = $currentToken.GetClientSecret()

    Write-Verbose "[Update-AzServicePrincipal] Refreshing service principal token for tenant '$tenantId', client '$clientId'."

    $Global:DSCAZDO_AuthenticationToken = $null
    $Global:DSCAZDO_AuthenticationToken = Get-AzServicePrincipalToken `
        -OrganizationName $Global:DSCAZDO_OrganizationName `
        -TenantId $tenantId `
        -ClientId $clientId `
        -ClientSecret $clientSecret

    return $Global:DSCAZDO_AuthenticationToken
}
