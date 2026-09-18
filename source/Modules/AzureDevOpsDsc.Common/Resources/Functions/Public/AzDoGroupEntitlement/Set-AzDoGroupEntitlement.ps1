<#
.SYNOPSIS
Updates the access level on an Azure DevOps group licensing rule.

.DESCRIPTION
Changes the access level the rule assigns. The change applies to the group's members, so lowering
the level takes that access away from everyone the group covers who has no other rule or direct
assignment granting it.

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
Set-AzDoGroupEntitlement -GroupDisplayName 'Contoso Developers' -AccountLicenseType 'stakeholder'
#>
Function Set-AzDoGroupEntitlement
{
    [CmdletBinding()]
    [OutputType([System.Object])]
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

    Write-Verbose "[Set-AzDoGroupEntitlement] Started."

    $OrganizationName    = Get-AzDoOrganizationName
    $groupEntitlementId  = $LookupResult.groupEntitlementId

    if ([String]::IsNullOrWhiteSpace($groupEntitlementId))
    {
        $entitlement = Get-DevOpsGroupEntitlement -Organization $OrganizationName -GroupDisplayName $GroupDisplayName
        $groupEntitlementId = $entitlement.id
    }

    if ([String]::IsNullOrWhiteSpace($groupEntitlementId))
    {
        Write-Error "[Set-AzDoGroupEntitlement] No licensing rule found for group '$GroupDisplayName'."
        return
    }

    if ([String]::IsNullOrWhiteSpace($AccountLicenseType))
    {
        Write-Verbose "[Set-AzDoGroupEntitlement] No AccountLicenseType supplied. No action taken."
        return
    }

    Write-Verbose "[Set-AzDoGroupEntitlement] Updating the licensing rule for group '$GroupDisplayName' to '$AccountLicenseType'."

    return (Update-DevOpsGroupEntitlement -Organization $OrganizationName `
        -GroupEntitlementId $groupEntitlementId -AccountLicenseType $AccountLicenseType)
}
