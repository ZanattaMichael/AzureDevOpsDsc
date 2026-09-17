<#
.SYNOPSIS
Retrieves the current state of an Azure DevOps service principal entitlement.

.DESCRIPTION
Looks the service principal up by its Entra object id and compares its access level against the
desired state.

Matching is by origin id rather than display name: display names are neither unique nor stable,
and a rename in Entra does not change the entitlement, so name matching would make the resource
create a duplicate after a rename.

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
Get-AzDoServicePrincipalEntitlement -OriginId '00000000-0000-0000-0000-000000000000' -AccountLicenseType 'express'
#>
Function Get-AzDoServicePrincipalEntitlement
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
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

    Write-Verbose "[Get-AzDoServicePrincipalEntitlement] Started."

    $OrganizationName = Get-AzDoOrganizationName

    $result = @{
        Ensure             = [Ensure]::Absent
        OriginId           = $OriginId
        DisplayName        = $DisplayName
        AccountLicenseType = $AccountLicenseType
        propertiesChanged  = @()
        status             = $null
    }

    $entitlement = Get-DevOpsServicePrincipalEntitlement -Organization $OrganizationName -OriginId $OriginId -DisplayName $DisplayName

    if ($null -eq $entitlement)
    {
        Write-Verbose "[Get-AzDoServicePrincipalEntitlement] No entitlement found for the service principal."
        $result.status = [DSCGetSummaryState]::NotFound
        return $result
    }

    $result.servicePrincipalEntitlementId = $entitlement.id
    $result.Ensure = [Ensure]::Present

    $currentLicense = $entitlement.accessLevel.accountLicenseType

    if ($AccountLicenseType -and ($AccountLicenseType -ne $currentLicense))
    {
        Write-Verbose "[Get-AzDoServicePrincipalEntitlement] Access level changed. Current: '$currentLicense', Desired: '$AccountLicenseType'."
        $result.status = [DSCGetSummaryState]::Changed
        $result.propertiesChanged += 'AccountLicenseType'
        return $result
    }

    $result.status = [DSCGetSummaryState]::Unchanged
    Write-Verbose "[Get-AzDoServicePrincipalEntitlement] Service principal entitlement is in the desired state."

    return $result
}
