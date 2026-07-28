<#
.SYNOPSIS
    Refreshes the certificate-based service principal Bearer token when it has expired.

.DESCRIPTION
    Reads the TenantId, ClientId, and certificate credentials from the current global token
    object, re-acquires a fresh token via Get-AzServicePrincipalCertificateToken, and updates
    the global variable. Called automatically by Add-AuthenticationHTTPHeader.
#>
Function Update-AzServicePrincipalCertificate
{
    if ($null -eq $Global:DSCAZDO_OrganizationName)
    {
        throw "[Update-AzServicePrincipalCertificate] Organization Name is not set. Please run 'New-AzDoAuthenticationProvider -OrganizationName <OrganizationName>'"
    }

    $currentToken = $Global:DSCAZDO_AuthenticationToken

    if ($null -eq $currentToken)
    {
        throw "[Update-AzServicePrincipalCertificate] No existing authentication token found. Cannot refresh."
    }

    $tenantId  = $currentToken.tenantId
    $clientId  = $currentToken.clientId

    Write-Verbose "[Update-AzServicePrincipalCertificate] Refreshing certificate token for tenant '$tenantId', client '$clientId'."

    $Global:DSCAZDO_AuthenticationToken = $null

    if (-not [String]::IsNullOrEmpty($currentToken.certificateThumbprint))
    {
        $Global:DSCAZDO_AuthenticationToken = Get-AzServicePrincipalCertificateToken `
            -OrganizationName $Global:DSCAZDO_OrganizationName `
            -TenantId $tenantId `
            -ClientId $clientId `
            -CertificateThumbprint $currentToken.certificateThumbprint
    }
    else
    {
        $Global:DSCAZDO_AuthenticationToken = Get-AzServicePrincipalCertificateToken `
            -OrganizationName $Global:DSCAZDO_OrganizationName `
            -TenantId $tenantId `
            -ClientId $clientId `
            -CertificatePath $currentToken.certificatePath `
            -CertificatePassword ([SecureString]$currentToken.certificatePassword)
    }

    return $Global:DSCAZDO_AuthenticationToken
}
