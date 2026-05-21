<#
.SYNOPSIS
    Acquires an Azure DevOps Bearer token using the OAuth 2.0 client credentials grant.

.DESCRIPTION
    Posts to the Azure AD token endpoint with client_id and client_secret to obtain a Bearer
    token scoped to the Azure DevOps resource (499b84ac-1321-427f-aa17-267ca6975798).

.PARAMETER OrganizationName
    Azure DevOps organization name, used when verifying the token.

.PARAMETER TenantId
    Azure AD tenant ID (GUID or domain name).

.PARAMETER ClientId
    Application (client) ID of the service principal.

.PARAMETER ClientSecret
    Client secret as plain text.

.PARAMETER SecureStringClientSecret
    Client secret as a SecureString.

.PARAMETER Verify
    If set, verifies the token by calling the Azure DevOps API after acquisition.
#>
Function Get-AzServicePrincipalToken
{
    [CmdletBinding(DefaultParameterSetName = 'PlainText')]
    param (
        [Parameter(Mandatory = $true)]
        [String]$OrganizationName,

        [Parameter(Mandatory = $true)]
        [String]$TenantId,

        [Parameter(Mandatory = $true)]
        [String]$ClientId,

        [Parameter(Mandatory = $true, ParameterSetName = 'PlainText')]
        [String]$ClientSecret,

        [Parameter(Mandatory = $true, ParameterSetName = 'SecureString')]
        [SecureString]$SecureStringClientSecret,

        [Parameter()]
        [Switch]$Verify
    )

    Write-Verbose "[Get-AzServicePrincipalToken] Acquiring service principal token for tenant '$TenantId', client '$ClientId'."

    # Resolve plain-text secret
    if ($PSCmdlet.ParameterSetName -eq 'SecureString')
    {
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureStringClientSecret)
        $ClientSecret = if ($isLinux) {
            [System.Runtime.InteropServices.Marshal]::PtrToStringUni($BSTR)
        } else {
            [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        }
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
        $secureForStorage = $SecureStringClientSecret
    }
    else
    {
        $secureForStorage = $ClientSecret | ConvertTo-SecureString -AsPlainText -Force
    }

    $tokenEndpoint = "https://login.microsoftonline.com/$TenantId/oauth2/token"
    $body = "grant_type=client_credentials&client_id=$([Uri]::EscapeDataString($ClientId))&client_secret=$([Uri]::EscapeDataString($ClientSecret))&resource=499b84ac-1321-427f-aa17-267ca6975798"

    try
    {
        $response = Invoke-RestMethod -Uri $tokenEndpoint -Method Post -Body $body -ContentType 'application/x-www-form-urlencoded'
    }
    catch
    {
        throw "[Get-AzServicePrincipalToken] Failed to acquire token from '$tokenEndpoint'. Error: $_"
    }

    if ([String]::IsNullOrEmpty($response.access_token))
    {
        throw "[Get-AzServicePrincipalToken] Access token not returned. Verify TenantId, ClientId, and ClientSecret are correct."
    }

    Write-Verbose "[Get-AzServicePrincipalToken] Token acquired successfully."

    $token = New-ServicePrincipalToken -TokenObj $response -TenantId $TenantId -ClientId $ClientId -ClientSecret $secureForStorage

    if (-not $Verify)
    {
        return $token
    }

    Write-Verbose "[Get-AzServicePrincipalToken] Verifying the connection to the Azure DevOps API."

    if (-not (Test-AzToken $token))
    {
        throw "[Get-AzServicePrincipalToken] Token verification failed. Unable to connect to Azure DevOps organization '$OrganizationName'."
    }

    Write-Verbose "[Get-AzServicePrincipalToken] Token verified successfully."
    return $token
}
