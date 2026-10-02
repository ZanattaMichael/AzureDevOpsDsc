<#
.SYNOPSIS
Adds a service principal to an Azure DevOps organization with an access level.

.DESCRIPTION
Creates a service principal entitlement, which is how a service principal or managed identity
becomes a member of the organization.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER OriginId
The Microsoft Entra object id of the service principal.

.PARAMETER DisplayName
The display name to record.

.PARAMETER AccountLicenseType
The access level to assign, for example 'express' or 'stakeholder'.

.EXAMPLE
New-DevOpsServicePrincipalEntitlement -Organization 'myorg' -OriginId $objectId -AccountLicenseType 'express'
#>
function New-DevOpsServicePrincipalEntitlement
{
    [CmdletBinding()]
    [OutputType([System.Object])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$Organization,

        [Parameter(Mandatory = $true)]
        [string]$OriginId,

        [Parameter()]
        [string]$DisplayName,

        [Parameter(Mandatory = $true)]
        [string]$AccountLicenseType,

        [Parameter()]
        [string]$ApiVersion = '7.1-preview.1'
    )

    $uri = 'https://vsaex.dev.azure.com/{0}/_apis/serviceprincipalentitlements?api-version={1}' -f $Organization, $ApiVersion

    $servicePrincipal = @{
        origin      = 'aad'
        originId    = $OriginId
        subjectKind = 'servicePrincipal'
    }

    if (-not [String]::IsNullOrWhiteSpace($DisplayName)) { $servicePrincipal.displayName = $DisplayName }

    $body = @{
        servicePrincipal = $servicePrincipal
        accessLevel      = @{
            licensingSource    = 'account'
            accountLicenseType = $AccountLicenseType
        }
    }

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'POST' -Body ($body | ConvertTo-Json -Depth 6))
    }
    catch
    {
        Write-Error "[New-DevOpsServicePrincipalEntitlement] Failed to create the service principal entitlement. Error: $_"
        return $null
    }
}
