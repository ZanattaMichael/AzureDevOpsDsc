<#
.SYNOPSIS
Removes a custom workflow state from a work item type.

.DESCRIPTION
Deletes a custom state. Only custom states can be deleted - an inherited state can be hidden
instead, which is a different operation.

Work items sitting in a deleted state are not moved. They keep the value, which then fails
validation on their next edit, so removing a state that is in use is worth doing deliberately.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProcessId
The process type id.

.PARAMETER WorkItemTypeRefName
The reference name of the work item type.

.PARAMETER StateId
The id of the state to delete.

.EXAMPLE
Remove-DevOpsProcessState -Organization 'myorg' -ProcessId $id -WorkItemTypeRefName 'Contoso.Incident' -StateId $stateId
#>
Function Remove-DevOpsProcessState
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
        [String]$StateId,

        [Parameter()]
        [String]$ApiVersion = '7.1-preview.1'
    )

    $uri = 'https://dev.azure.com/{0}/_apis/work/processes/{1}/workItemTypes/{2}/states/{3}?api-version={4}' -f
        $Organization, $ProcessId, $WorkItemTypeRefName, $StateId, $ApiVersion

    try
    {
        return (Invoke-AzDevOpsApiRestMethod -Uri $uri -Method 'DELETE')
    }
    catch
    {
        Write-Error "[Remove-DevOpsProcessState] Failed to remove state '$StateId' from '$WorkItemTypeRefName'. Error: $_"
        return $null
    }
}
