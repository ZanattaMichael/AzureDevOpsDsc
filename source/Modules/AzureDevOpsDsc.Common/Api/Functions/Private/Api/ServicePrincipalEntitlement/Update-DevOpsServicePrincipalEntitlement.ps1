<#
.SYNOPSIS
Updates the access level on an Azure DevOps service principal entitlement.

.DESCRIPTION
PATCHes the entitlement using JSON Patch, which is what this endpoint expects.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ServicePrincipalEntitlementId
The id of the entitlement to update.

.PARAMETER AccountLicenseType
The access level the service principal should have.

.EXAMPLE
Update-DevOpsServicePrincipalEntitlement -Organization 'myorg' -ServicePrincipalEntitlementId $id -AccountLicenseType 'stakeholder'
#>
function Update-DevOpsServicePrincipalEntitlement
{
    [CmdletBinding()]
    [OutputType([System.Object])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$Organization,

        [Parameter(Mandatory = $true)]
        [string]$ServicePrincipalEntitlementId,

        [Parameter(Mandatory = $true)]
        [string]$AccountLicenseType,

        [Parameter()]
        [string]$ApiVersion = '7.1-preview.1'
    )

    $uri = 'https://vsaex.dev.azure.com/{0}/_apis/serviceprincipalentitlements/{1}?api-version={2}' -f
        $Organization, $ServicePrincipalEntitlementId, $ApiVersion

    $body = @(
        @{
            op    = 'replace'
            path  = '/accessLevel'
            from  = $null
            value = @{
                licensingSource    = 'account'
                accountLicenseType = $AccountLicenseType
            }
        }
    )

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'PATCH' `
            -HttpContentType 'application/json-patch+json' -Body ($body | ConvertTo-Json -Depth 6 -AsArray))
    }
    catch
    {
        Write-Error "[Update-DevOpsServicePrincipalEntitlement] Failed to update service principal entitlement '$ServicePrincipalEntitlementId'. Error: $_"
        return $null
    }
}
