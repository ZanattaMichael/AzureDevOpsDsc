<#
.SYNOPSIS
Removes an Azure DevOps group licensing rule.

.DESCRIPTION
Deletes the rule. This does not remove anyone from the organization: members keep any license
held directly or granted by another rule, and lose only what this rule gave them.

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
Remove-AzDoGroupEntitlement -GroupDisplayName 'Contoso Developers'
#>
Function Remove-AzDoGroupEntitlement
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

    Write-Verbose "[Remove-AzDoGroupEntitlement] Started."

    $OrganizationName   = Get-AzDoOrganizationName
    $groupEntitlementId = $LookupResult.groupEntitlementId

    if ([String]::IsNullOrWhiteSpace($groupEntitlementId))
    {
        $entitlement = Get-DevOpsGroupEntitlement -Organization $OrganizationName -GroupDisplayName $GroupDisplayName
        $groupEntitlementId = $entitlement.id
    }

    if ([String]::IsNullOrWhiteSpace($groupEntitlementId))
    {
        Write-Verbose "[Remove-AzDoGroupEntitlement] No licensing rule found for group '$GroupDisplayName'. Nothing to remove."
        return
    }

    Write-Verbose "[Remove-AzDoGroupEntitlement] Removing the licensing rule for group '$GroupDisplayName'."

    return (Remove-DevOpsGroupEntitlement -Organization $OrganizationName -GroupEntitlementId $groupEntitlementId)
}
