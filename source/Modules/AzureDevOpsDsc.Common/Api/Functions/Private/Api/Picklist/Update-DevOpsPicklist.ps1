<#
.SYNOPSIS
Updates a picklist's items.

.DESCRIPTION
Replaces the picklist with the supplied definition. The API takes a PUT, so the item list sent is
the complete list - items absent from it are removed.

Removing an item that work items already use does not rewrite those work items. They keep the
value, which then fails validation on the next edit, so narrowing a picklist is worth doing
deliberately.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER PicklistId
The id of the picklist to update.

.PARAMETER PicklistName
The name the picklist should have.

.PARAMETER Items
The complete list of values.

.PARAMETER PicklistType
'String' or 'Integer'.

.PARAMETER IsSuggested
Whether the list is a suggestion rather than a closed set.

.EXAMPLE
Update-DevOpsPicklist -Organization 'myorg' -PicklistId $id -PicklistName 'Severity' -Items @('Low','Medium','High')
#>
Function Update-DevOpsPicklist
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]$Organization,

        [Parameter(Mandatory = $true)]
        [String]$PicklistId,

        [Parameter(Mandatory = $true)]
        [String]$PicklistName,

        [Parameter()]
        [AllowEmptyCollection()]
        [String[]]$Items = @(),

        [Parameter()]
        [ValidateSet('String', 'Integer')]
        [String]$PicklistType = 'String',

        [Parameter()]
        [Boolean]$IsSuggested = $false,

        [Parameter()]
        [String]$ApiVersion = '7.1-preview.1'
    )

    $uri = 'https://dev.azure.com/{0}/_apis/work/processes/lists/{1}?api-version={2}' -f
        $Organization, $PicklistId, $ApiVersion

    $body = @{
        id          = $PicklistId
        name        = $PicklistName
        type        = $PicklistType
        items       = @($Items)
        isSuggested = $IsSuggested
    }

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'PUT' -Body ($body | ConvertTo-Json -Depth 5))
    }
    catch
    {
        Write-Error "[Update-DevOpsPicklist] Failed to update picklist '$PicklistName'. Error: $_"
        return $null
    }
}
