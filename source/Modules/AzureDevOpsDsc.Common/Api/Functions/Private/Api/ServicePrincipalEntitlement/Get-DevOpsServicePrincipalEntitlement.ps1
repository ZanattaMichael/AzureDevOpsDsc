<#
.SYNOPSIS
Finds an Azure DevOps service principal entitlement by origin id or display name.

.DESCRIPTION
Service principals and managed identities are organization members in their own right and need an
access level, exactly as users do. AzDoUserEntitlement does not cover them - they live on a
separate endpoint.

The service principal entitlements endpoint is a preview API. If it is unavailable in an
organization, this returns $null rather than throwing, so a Get reads as "not found" instead of
failing the whole configuration.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER OriginId
The Microsoft Entra object id of the service principal. Preferred, because it is stable across
renames.

.PARAMETER DisplayName
The display name, used when no origin id is supplied.

.OUTPUTS
The matching service principal entitlement, or $null.

.EXAMPLE
Get-DevOpsServicePrincipalEntitlement -Organization 'myorg' -OriginId '00000000-0000-0000-0000-000000000000'
#>
function Get-DevOpsServicePrincipalEntitlement
{
    [CmdletBinding()]
    [OutputType([System.Object])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$Organization,

        [Parameter()]
        [string]$OriginId,

        [Parameter()]
        [string]$DisplayName,

        [Parameter()]
        [string]$ApiVersion = '7.1-preview.1'
    )

    $uri = 'https://vsaex.dev.azure.com/{0}/_apis/serviceprincipalentitlements?api-version={1}' -f $Organization, $ApiVersion

    try
    {
        $response = Invoke-AzDevOpsApiRestMethod -Uri $uri -Method Get
    }
    catch
    {
        Write-Verbose "[Get-DevOpsServicePrincipalEntitlement] Service principal entitlement lookup failed: $_"
        return $null
    }

    $items = if ($null -ne $response.members) { $response.members } elseif ($null -ne $response.value) { $response.value } else { @($response) }

    # Match on origin id when one was supplied: display names are not unique and can be changed in
    # Entra without the entitlement changing at all.
    if (-not [String]::IsNullOrWhiteSpace($OriginId))
    {
        return $items | Where-Object { $_.servicePrincipal.originId -eq $OriginId } | Select-Object -First 1
    }

    return $items | Where-Object {
        ($_.servicePrincipal.displayName -eq $DisplayName) -or ($_.servicePrincipal.principalName -eq $DisplayName)
    } | Select-Object -First 1
}
