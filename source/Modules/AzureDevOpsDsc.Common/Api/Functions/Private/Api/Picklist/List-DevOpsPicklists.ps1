<#
.SYNOPSIS
Lists the picklists defined in an Azure DevOps organization.

.DESCRIPTION
Picklists are organization-scoped, not process-scoped: one picklist can back fields in several
processes. The listing returns metadata only - the items of a picklist come back from
Get-DevOpsPicklist.

.PARAMETER Organization
The name of the Azure DevOps organization.

.EXAMPLE
List-DevOpsPicklists -Organization 'myorg'
#>
Function List-DevOpsPicklists
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]$Organization,

        [Parameter()]
        [String]$ApiVersion = '7.1-preview.1'
    )

    $uri = 'https://dev.azure.com/{0}/_apis/work/processes/lists?api-version={1}' -f $Organization, $ApiVersion

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'GET').value
    }
    catch
    {
        Write-Error "[List-DevOpsPicklists] Failed to list picklists for organization '$Organization'. Error: $_"
        return $null
    }
}
