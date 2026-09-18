<#
.SYNOPSIS
Retrieves the current state of an Azure DevOps group licensing rule.

.DESCRIPTION
Looks up the group entitlement and compares the access level it assigns against the desired
state.

.PARAMETER GroupDisplayName
The display name or principal name of the group.

.PARAMETER AccountLicenseType
The access level the rule assigns.

.PARAMETER GroupOrigin
The identity origin: 'aad' or 'vsts'.

.PARAMETER GroupOriginId
The Entra object id of the group.

.PARAMETER LookupResult
The lookup result supplied by the DSC base class.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.

.EXAMPLE
Get-AzDoGroupEntitlement -GroupDisplayName 'Contoso Developers' -AccountLicenseType 'express'
#>
Function Get-AzDoGroupEntitlement
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [Alias('GroupName')]
        [System.String]$GroupDisplayName,

        [Parameter()]
        [System.String]$AccountLicenseType,

        [Parameter()]
        [System.String]$GroupOrigin,

        [Parameter()]
        [System.String]$GroupOriginId,

        [Parameter()]
        [HashTable]$LookupResult,

        [Parameter()]
        [Ensure]$Ensure,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Get-AzDoGroupEntitlement] Started."

    $OrganizationName = Get-AzDoOrganizationName

    $result = @{
        Ensure             = [Ensure]::Absent
        GroupDisplayName   = $GroupDisplayName
        AccountLicenseType = $AccountLicenseType
        propertiesChanged  = @()
        status             = $null
    }

    $entitlement = Get-DevOpsGroupEntitlement -Organization $OrganizationName -GroupDisplayName $GroupDisplayName

    if ($null -eq $entitlement)
    {
        Write-Verbose "[Get-AzDoGroupEntitlement] No licensing rule found for group '$GroupDisplayName'."
        $result.status = [DSCGetSummaryState]::NotFound
        return $result
    }

    # Carry the resolved id so Set and Remove do not need a second lookup.
    $result.groupEntitlementId = $entitlement.id
    $result.Ensure             = [Ensure]::Present

    $currentLicense = $entitlement.licenseRule.accountLicenseType

    if ($AccountLicenseType -and ($AccountLicenseType -ne $currentLicense))
    {
        Write-Verbose "[Get-AzDoGroupEntitlement] Access level changed. Current: '$currentLicense', Desired: '$AccountLicenseType'."
        $result.status = [DSCGetSummaryState]::Changed
        $result.propertiesChanged += 'AccountLicenseType'
        return $result
    }

    $result.status = [DSCGetSummaryState]::Unchanged
    Write-Verbose "[Get-AzDoGroupEntitlement] Group licensing rule is in the desired state."

    return $result
}
