<#
.SYNOPSIS
Lists the behaviors a work item type is associated with.

.DESCRIPTION
Returns the behavior associations for a work item type - which backlog levels it appears on, and
whether it is the default type for creating new items at that level.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProcessId
The process type id.

.PARAMETER WorkItemTypeRefName
The reference name of the work item type.

.EXAMPLE
List-DevOpsWorkItemTypeBehaviors -Organization 'myorg' -ProcessId $id -WorkItemTypeRefName 'Contoso.Incident'
#>
Function List-DevOpsWorkItemTypeBehaviors
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

    $uri = 'https://dev.azure.com/{0}/_apis/work/processes/{1}/workitemtypesbehaviors/{2}/behaviors?api-version={3}' -f
        $Organization, $ProcessId, $WorkItemTypeRefName, $ApiVersion

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'GET').value
    }
    catch
    {
        Write-Verbose "[List-DevOpsWorkItemTypeBehaviors] Behavior lookup for '$WorkItemTypeRefName' failed: $_"
        return $null
    }
}
