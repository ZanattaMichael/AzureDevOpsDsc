<#
.SYNOPSIS
Lists the workflow states on a work item type of an inherited process.

.DESCRIPTION
Returns the states the work item type exposes, inherited and custom alike. Each carries its
category ('Proposed', 'InProgress', 'Resolved', 'Completed', 'Removed'), colour and order.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProcessId
The process type id.

.PARAMETER WorkItemTypeRefName
The reference name of the work item type.

.EXAMPLE
List-DevOpsProcessStates -Organization 'myorg' -ProcessId $id -WorkItemTypeRefName 'Contoso.Incident'
#>
Function List-DevOpsProcessStates
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]$Organization,

        [Parameter(Mandatory = $true)]
        [String]$ProcessId,

        [Parameter(Mandatory = $true)]
        [String]$WorkItemTypeRefName,

        [Parameter()]
        [String]$ApiVersion = '7.1-preview.1'
    )

    $uri = 'https://dev.azure.com/{0}/_apis/work/processes/{1}/workItemTypes/{2}/states?api-version={3}' -f
        $Organization, $ProcessId, $WorkItemTypeRefName, $ApiVersion

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'GET').value
    }
    catch
    {
        Write-Error "[List-DevOpsProcessStates] Failed to list states for work item type '$WorkItemTypeRefName'. Error: $_"
        return $null
    }
}
