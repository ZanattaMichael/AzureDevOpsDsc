<#
.SYNOPSIS
Removes an Azure DevOps picklist.

.DESCRIPTION
Deletes the picklist. A picklist still backing a field cannot be deleted - the API rejects the
attempt rather than orphaning the field, and that rejection is surfaced rather than swallowed.

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
Remove-AzDoPicklist -PicklistName 'Severity'
#>
Function Remove-AzDoPicklist
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

    Write-Verbose "[Remove-AzDoPicklist] Started."

    $OrganizationName = Get-AzDoOrganizationName
    $picklistId       = $LookupResult.picklistId

    if ([String]::IsNullOrWhiteSpace($picklistId))
    {
        $picklists  = List-DevOpsPicklists -Organization $OrganizationName
        $picklistId = ($picklists | Where-Object { $_.name -eq $PicklistName } | Select-Object -First 1).id
    }

    if ([String]::IsNullOrWhiteSpace($picklistId))
    {
        Write-Verbose "[Remove-AzDoPicklist] Picklist '$PicklistName' does not exist. Nothing to remove."
        return
    }

    Write-Verbose "[Remove-AzDoPicklist] Removing picklist '$PicklistName'."

    return (Remove-DevOpsPicklist -Organization $OrganizationName -PicklistId $picklistId)
}
