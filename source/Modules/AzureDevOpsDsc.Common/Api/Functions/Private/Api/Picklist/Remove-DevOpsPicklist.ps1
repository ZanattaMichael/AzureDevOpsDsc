<#
.SYNOPSIS
Deletes a picklist from an Azure DevOps organization.

.DESCRIPTION
Deletes the picklist. A picklist still backing a field cannot be deleted, and the API rejects the
attempt rather than orphaning the field.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER PicklistId
The id of the picklist to delete.

.EXAMPLE
Remove-DevOpsPicklist -Organization 'myorg' -PicklistId $id
#>
Function Remove-DevOpsPicklist
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
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'DELETE')
    }
    catch
    {
        Write-Error "[Remove-DevOpsPicklist] Failed to delete picklist '$PicklistId'. Error: $_"
        return $null
    }
}
