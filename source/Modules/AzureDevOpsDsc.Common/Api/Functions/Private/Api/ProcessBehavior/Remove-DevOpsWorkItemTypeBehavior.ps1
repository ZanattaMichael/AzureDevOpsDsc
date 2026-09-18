<#
.SYNOPSIS
Removes a work item type's association with a behavior.

.DESCRIPTION
Removes the association, so the work item type no longer appears on that backlog level. The work
item type and its work items are untouched - only their presence on the backlog changes.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProcessId
The process type id.

.PARAMETER WorkItemTypeRefName
The reference name of the work item type.

.PARAMETER BehaviorRefName
The reference name of the behavior.

.EXAMPLE
Remove-DevOpsWorkItemTypeBehavior -Organization 'myorg' -ProcessId $id -WorkItemTypeRefName 'Contoso.Incident' -BehaviorRefName 'System.RequirementBacklogBehavior'
#>
Function Remove-DevOpsWorkItemTypeBehavior
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]$Organization,

        [Parameter(Mandatory = $true)]
        [String]$ProcessId,

        [Parameter(Mandatory = $true)]
        [String]$WorkItemTypeRefName,

        [Parameter(Mandatory = $true)]
        [String]$BehaviorRefName,

        [Parameter()]
        [String]$ApiVersion = '7.1-preview.1'
    )

    $uri = 'https://dev.azure.com/{0}/_apis/work/processes/{1}/workitemtypesbehaviors/{2}/behaviors/{3}?api-version={4}' -f
        $Organization, $ProcessId, $WorkItemTypeRefName, $BehaviorRefName, $ApiVersion

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'DELETE')
    }
    catch
    {
        Write-Error "[Remove-DevOpsWorkItemTypeBehavior] Failed to remove behavior '$BehaviorRefName' from '$WorkItemTypeRefName'. Error: $_"
        return $null
    }
}
