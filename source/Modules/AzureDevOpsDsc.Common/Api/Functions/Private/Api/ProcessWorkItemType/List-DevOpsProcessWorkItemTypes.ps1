<#
.SYNOPSIS
Lists the work item types on an inherited process.

.DESCRIPTION
Returns every work item type the process exposes: those inherited from its parent, and any custom
types added to it. The 'customization' property distinguishes them - 'system' for an untouched
inherited type, 'inherited' for one that has been customized, and 'custom' for one created on this
process.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProcessId
The process type id.

.EXAMPLE
List-DevOpsProcessWorkItemTypes -Organization 'myorg' -ProcessId $processId
#>
Function List-DevOpsProcessWorkItemTypes
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]$Organization,

        [Parameter(Mandatory = $true)]
        [String]$ProcessId,

        [Parameter()]
        [String]$ApiVersion = '7.1-preview.2'
    )

    $uri = 'https://dev.azure.com/{0}/_apis/work/processes/{1}/workitemtypes?api-version={2}' -f
        $Organization, $ProcessId, $ApiVersion

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'GET').value
    }
    catch
    {
        Write-Error "[List-DevOpsProcessWorkItemTypes] Failed to list work item types for process '$ProcessId'. Error: $_"
        return $null
    }
}
