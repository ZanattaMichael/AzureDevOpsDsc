<#
.SYNOPSIS
Lists the behaviors on an inherited process.

.DESCRIPTION
Behaviors are the backlog levels a process exposes - Epics, Features, Stories, Tasks - and what
binds a work item type to a backlog. A custom work item type does not appear on any backlog until
it is associated with a behavior.

Behaviors are process-scoped, not work-item-type-scoped, which is why this lists them from the
process.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProcessId
The process type id.

.EXAMPLE
List-DevOpsProcessBehaviors -Organization 'myorg' -ProcessId $id
#>
Function List-DevOpsProcessBehaviors
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

    $uri = 'https://dev.azure.com/{0}/_apis/work/processes/{1}/behaviors?api-version={2}' -f
        $Organization, $ProcessId, $ApiVersion

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'GET').value
    }
    catch
    {
        Write-Error "[List-DevOpsProcessBehaviors] Failed to list behaviors for process '$ProcessId'. Error: $_"
        return $null
    }
}
