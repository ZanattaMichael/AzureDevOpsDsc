<#
.SYNOPSIS
Removes a service principal from the Azure DevOps organization.

.DESCRIPTION
Deletes the entitlement, which removes the service principal from the organization. Anything
running as that identity - pipelines, federated deployments - loses access.

.PARAMETER OriginId
The Microsoft Entra object id of the service principal.

.PARAMETER DisplayName
A display name recorded with the entitlement.

.PARAMETER AccountLicenseType
The access level to assign.

.PARAMETER LookupResult
The lookup result supplied by the DSC base class.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.

.EXAMPLE
Remove-AzDoServicePrincipalEntitlement -OriginId '00000000-0000-0000-0000-000000000000'
#>
Function Remove-AzDoServicePrincipalEntitlement
{
    [CmdletBinding()]
    [OutputType([System.Object])]
    param
    (
        [Parameter(Mandatory = $true)]
        [Alias('ObjectId')]
        [System.String]$OriginId,

        [Parameter()]
        [Alias('Name')]
        [System.String]$DisplayName,

        [Parameter()]
        [System.String]$AccountLicenseType,

        [Parameter()]
        [HashTable]$LookupResult,

        [Parameter()]
        [Ensure]$Ensure,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Remove-AzDoServicePrincipalEntitlement] Started."

    $OrganizationName = Get-AzDoOrganizationName
    $entitlementId    = $LookupResult.servicePrincipalEntitlementId

    if ([String]::IsNullOrWhiteSpace($entitlementId))
    {
        $entitlement   = Get-DevOpsServicePrincipalEntitlement -Organization $OrganizationName -OriginId $OriginId -DisplayName $DisplayName
        $entitlementId = $entitlement.id
    }

    if ([String]::IsNullOrWhiteSpace($entitlementId))
    {
        Write-Verbose "[Remove-AzDoServicePrincipalEntitlement] No entitlement found for the service principal. Nothing to remove."
        return
    }

    Write-Verbose "[Remove-AzDoServicePrincipalEntitlement] Removing the service principal from the organization."

    return (Remove-DevOpsServicePrincipalEntitlement -Organization $OrganizationName -ServicePrincipalEntitlementId $entitlementId)
}
