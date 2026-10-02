<#
.SYNOPSIS
Updates an Azure DevOps picklist.

.DESCRIPTION
Replaces the picklist's items and settings. The update endpoint takes the complete list, so items
absent from the configuration are removed.

Removing an item does not rewrite work items that already carry it. They keep the value, which
then fails validation the next time they are edited.

.PARAMETER PicklistName
The name of the picklist.

.PARAMETER Items
The complete set of allowed values.

.PARAMETER PicklistType
'String' or 'Integer'.

.PARAMETER IsSuggested
Whether the list is a suggestion rather than a closed set.

.PARAMETER LookupResult
The lookup result supplied by the DSC base class.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.

.EXAMPLE
Set-AzDoPicklist -PicklistName 'Severity' -Items @('Low','Medium','High')
#>
Function Set-AzDoPicklist
{
    [CmdletBinding()]
    [OutputType([System.Object])]
    param
    (
        [Parameter(Mandatory = $true)]
        [Alias('Name')]
        [System.String]$PicklistName,

        [Parameter()]
        [AllowEmptyCollection()]
        [System.String[]]$Items,

        [Parameter()]
        [System.String]$PicklistType = 'String',

        [Parameter()]
        [System.Boolean]$IsSuggested,

        [Parameter()]
        [HashTable]$LookupResult,

        [Parameter()]
        [Ensure]$Ensure,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Set-AzDoPicklist] Started."

    if ($LookupResult.reason -eq 'PicklistTypeImmutable')
    {
        Write-Error "[Set-AzDoPicklist] Cannot change the type of picklist '$PicklistName' after creation. No change was made."
        return
    }

    $OrganizationName = Get-AzDoOrganizationName
    $picklistId       = $LookupResult.picklistId

    if ([String]::IsNullOrWhiteSpace($picklistId))
    {
        $picklists  = List-DevOpsPicklists -Organization $OrganizationName
        $picklistId = ($picklists | Where-Object { $_.name -eq $PicklistName } | Select-Object -First 1).id
    }

    if ([String]::IsNullOrWhiteSpace($picklistId))
    {
        Write-Error "[Set-AzDoPicklist] Picklist '$PicklistName' was not found."
        return
    }

    # The live list supplies any value the configuration does not state, so updating items does not
    # silently reset the suggested flag.
    $live = $LookupResult.liveCache

    $params = @{
        Organization = $OrganizationName
        PicklistId   = $picklistId
        PicklistName = $PicklistName
        Items        = if ($null -ne $Items) { @($Items) } else { @($live.items) }
        IsSuggested  = if ($PSBoundParameters.ContainsKey('IsSuggested')) { [bool]$IsSuggested } else { [bool]$live.isSuggested }
    }

    if (-not [String]::IsNullOrWhiteSpace($PicklistType)) { $params.PicklistType = $PicklistType }

    Write-Verbose "[Set-AzDoPicklist] Updating picklist '$PicklistName'."

    return (Update-DevOpsPicklist @params)
}
