<#
.SYNOPSIS
Removes a service principal from an Azure DevOps organization.

.DESCRIPTION
Deletes the service principal entitlement, which removes the service principal from the
organization. Anything running as that identity loses access.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ServicePrincipalEntitlementId
The id of the entitlement to delete.

.EXAMPLE
Remove-DevOpsServicePrincipalEntitlement -Organization 'myorg' -ServicePrincipalEntitlementId $id
#>
function Remove-DevOpsServicePrincipalEntitlement
{
    [CmdletBinding()]
    [OutputType([System.Object])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$Organization,

        [Parameter(Mandatory = $true)]
        [string]$ServicePrincipalEntitlementId,

        [Parameter()]
        [string]$ApiVersion = '7.1-preview.1'
    )

    $uri = 'https://vsaex.dev.azure.com/{0}/_apis/serviceprincipalentitlements/{1}?api-version={2}' -f
        $Organization, $ServicePrincipalEntitlementId, $ApiVersion

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'DELETE')
    }
    catch
    {
        Write-Error "[Remove-DevOpsServicePrincipalEntitlement] Failed to delete service principal entitlement '$ServicePrincipalEntitlementId'. Error: $_"
        return $null
    }
}
