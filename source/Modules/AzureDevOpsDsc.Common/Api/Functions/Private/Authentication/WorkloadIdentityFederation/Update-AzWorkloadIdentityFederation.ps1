<#
.SYNOPSIS
    Refreshes the Workload Identity Federation Bearer token when it has expired.

.DESCRIPTION
    Reads the TenantId, ClientId, and federated-token source from the current global token
    object, re-acquires a fresh federated assertion and a fresh Azure AD token via
    Get-AzWorkloadIdentityFederationToken, and updates the global variable. Called automatically
    by Add-AuthenticationHTTPHeader when isExpired() returns true.

    A token acquired from a manually-supplied federated token ('Manual' source) cannot be
    refreshed here - there is nothing to re-read. The caller must obtain a fresh federated token
    and call New-AzDoAuthenticationProvider again before the current one expires.
#>
Function Update-AzWorkloadIdentityFederation
{
    if ($null -eq $Global:DSCAZDO_OrganizationName)
    {
        throw "[Update-AzWorkloadIdentityFederation] Organization Name is not set. Please run 'New-AzDoAuthenticationProvider -OrganizationName <OrganizationName>'"
    }

    $currentToken = $Global:DSCAZDO_AuthenticationToken

    if ($null -eq $currentToken)
    {
        throw "[Update-AzWorkloadIdentityFederation] No existing authentication token found. Cannot refresh."
    }

    $tenantId = $currentToken.tenantId
    $clientId = $currentToken.clientId
    $source   = $currentToken.federatedTokenSource

    Write-Verbose "[Update-AzWorkloadIdentityFederation] Refreshing workload identity federation token for tenant '$tenantId', client '$clientId' (source: $source)."

    if ($source -eq 'Manual')
    {
        throw "[Update-AzWorkloadIdentityFederation] The current token was created from a manually-supplied federated token, which cannot be refreshed automatically. Obtain a fresh federated token and call New-AzDoAuthenticationProvider again."
    }

    $Global:DSCAZDO_AuthenticationToken = $null

    if ($source -eq 'File')
    {
        $Global:DSCAZDO_AuthenticationToken = Get-AzWorkloadIdentityFederationToken `
            -OrganizationName $Global:DSCAZDO_OrganizationName `
            -TenantId $tenantId `
            -ClientId $clientId `
            -FederatedTokenFile $currentToken.federatedTokenFile
    }
    elseif ($source -eq 'GitHubActions')
    {
        $Global:DSCAZDO_AuthenticationToken = Get-AzWorkloadIdentityFederationToken `
            -OrganizationName $Global:DSCAZDO_OrganizationName `
            -TenantId $tenantId `
            -ClientId $clientId `
            -GitHubActions
    }
    else
    {
        throw "[Update-AzWorkloadIdentityFederation] Unknown federated token source '$source' on the current token."
    }

    return $Global:DSCAZDO_AuthenticationToken
}
