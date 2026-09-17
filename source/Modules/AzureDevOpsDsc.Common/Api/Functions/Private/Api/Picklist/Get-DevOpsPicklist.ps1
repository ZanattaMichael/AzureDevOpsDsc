<#
.SYNOPSIS
Retrieves a single picklist, including its items.

.DESCRIPTION
The picklist listing returns metadata without items, so the items have to be fetched per list.
This is what makes item-level drift detection possible.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER PicklistId
The id of the picklist.

.EXAMPLE
Get-DevOpsPicklist -Organization 'myorg' -PicklistId $id
#>
Function Get-DevOpsPicklist
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]$Organization,

        [Parameter(Mandatory = $true)]
        [String]$PicklistId,

        [Parameter()]
        [String]$ApiVersion = '7.1-preview.1'
    )

    $uri = 'https://dev.azure.com/{0}/_apis/work/processes/lists/{1}?api-version={2}' -f
        $Organization, $PicklistId, $ApiVersion

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'GET')
    }
    catch
    {
        Write-Verbose "[Get-DevOpsPicklist] Picklist '$PicklistId' could not be retrieved: $_"
        return $null
    }
}
