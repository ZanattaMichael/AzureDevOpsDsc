<#
.SYNOPSIS
Retrieves the current state of an Azure DevOps picklist.

.DESCRIPTION
Finds the picklist by name and compares its items and settings against the desired state.

The listing endpoint returns picklist metadata without items, so the matching list is fetched
individually - item-level drift cannot be detected from the listing alone.

Items are compared as an ordered sequence, because the order is what the picker shows.

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
Get-AzDoPicklist -PicklistName 'Severity' -Items @('Low','High')
#>
Function Get-AzDoPicklist
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
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

    Write-Verbose "[Get-AzDoPicklist] Started."

    $OrganizationName = Get-AzDoOrganizationName

    $result = @{
        Ensure            = [Ensure]::Absent
        PicklistName      = $PicklistName
        propertiesChanged = @()
        status            = $null
        reason            = $null
    }

    $picklists = List-DevOpsPicklists -Organization $OrganizationName
    $match     = $picklists | Where-Object { $_.name -eq $PicklistName } | Select-Object -First 1

    if ($null -eq $match)
    {
        Write-Verbose "[Get-AzDoPicklist] Picklist '$PicklistName' does not exist."
        $result.status = [DSCGetSummaryState]::NotFound
        return $result
    }

    # The listing carries no items, so the list itself has to be fetched to compare them.
    $picklist = Get-DevOpsPicklist -Organization $OrganizationName -PicklistId $match.id

    if ($null -eq $picklist)
    {
        Write-Error "[Get-AzDoPicklist] Picklist '$PicklistName' was listed but could not be retrieved."
        $result.status = [DSCGetSummaryState]::Error
        return $result
    }

    $result.picklistId = $picklist.id
    $result.liveCache  = $picklist
    $result.Ensure     = [Ensure]::Present

    $propertiesChanged = @()

    if ($PSBoundParameters.ContainsKey('Items') -and $null -ne $Items)
    {
        $currentItems = @($picklist.items)

        # Ordered comparison: the order is the order shown in the picker.
        if ((@($Items) -join '|') -ne ($currentItems -join '|'))
        {
            Write-Verbose "[Get-AzDoPicklist] Items differ for picklist '$PicklistName'."
            $propertiesChanged += 'Items'
        }
    }

    if ($PSBoundParameters.ContainsKey('IsSuggested'))
    {
        if ([bool]$picklist.isSuggested -ne $IsSuggested)
        {
            Write-Verbose "[Get-AzDoPicklist] IsSuggested differs for picklist '$PicklistName'."
            $propertiesChanged += 'IsSuggested'
        }
    }

    # The type is fixed at creation. Report the mismatch rather than attempting a recreate, which
    # would drop every value already stored in fields backed by this list.
    if (-not [String]::IsNullOrWhiteSpace($PicklistType) -and ($picklist.type -ne $PicklistType))
    {
        Write-Error "[Get-AzDoPicklist] Picklist '$PicklistName' is of type '$($picklist.type)' but the configuration asks for '$PicklistType'. A picklist's type cannot be changed after creation."
        $result.status = [DSCGetSummaryState]::Error
        $result.reason = 'PicklistTypeImmutable'
        return $result
    }

    $result.propertiesChanged = $propertiesChanged
    $result.status = if ($propertiesChanged.Count -gt 0) { [DSCGetSummaryState]::Changed } else { [DSCGetSummaryState]::Unchanged }

    Write-Verbose "[Get-AzDoPicklist] Picklist '$PicklistName' status: $($result.status)."

    return $result
}
