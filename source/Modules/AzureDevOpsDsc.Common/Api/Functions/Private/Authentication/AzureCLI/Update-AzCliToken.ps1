<#
.SYNOPSIS
    Refreshes the Azure CLI Bearer token when it has expired.

.DESCRIPTION
    Re-invokes Get-AzCliToken to obtain a fresh token and updates the global variable.
    Called automatically by Add-AuthenticationHTTPHeader when isExpired() returns true.
    No credentials are needed — the CLI manages its own login session.
#>
Function Update-AzCliToken
{
    if ($null -eq $Global:DSCAZDO_OrganizationName)
    {
        throw "[Update-AzCliToken] Organization Name is not set. Please run 'New-AzDoAuthenticationProvider -OrganizationName <OrganizationName>'"
    }

    Write-Verbose "[Update-AzCliToken] Refreshing Azure CLI token."

    $Global:DSCAZDO_AuthenticationToken = $null
    $Global:DSCAZDO_AuthenticationToken = Get-AzCliToken -OrganizationName $Global:DSCAZDO_OrganizationName

    return $Global:DSCAZDO_AuthenticationToken
}
