<#
.SYNOPSIS
Updates the access level of an Azure DevOps service principal.

.DESCRIPTION
Changes the access level assigned to the service principal.

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
Set-AzDoServicePrincipalEntitlement -OriginId '00000000-0000-0000-0000-000000000000' -AccountLicenseType 'stakeholder'
#>
Function Set-AzDoServicePrincipalEntitlement
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

    Write-Verbose "[Set-AzDoServicePrincipalEntitlement] Started."

    $OrganizationName = Get-AzDoOrganizationName
    $entitlementId    = $LookupResult.servicePrincipalEntitlementId

    if ([String]::IsNullOrWhiteSpace($entitlementId))
    {
        $entitlement   = Get-DevOpsServicePrincipalEntitlement -Organization $OrganizationName -OriginId $OriginId -DisplayName $DisplayName
        $entitlementId = $entitlement.id
    }

    if ([String]::IsNullOrWhiteSpace($entitlementId))
    {
        Write-Error "[Set-AzDoServicePrincipalEntitlement] No entitlement found for the service principal."
        return
    }

    if ([String]::IsNullOrWhiteSpace($AccountLicenseType))
    {
        Write-Verbose "[Set-AzDoServicePrincipalEntitlement] No AccountLicenseType supplied. No action taken."
        return
    }

    Write-Verbose "[Set-AzDoServicePrincipalEntitlement] Updating the service principal access level to '$AccountLicenseType'."

    return (Update-DevOpsServicePrincipalEntitlement -Organization $OrganizationName `
        -ServicePrincipalEntitlementId $entitlementId -AccountLicenseType $AccountLicenseType)
}
