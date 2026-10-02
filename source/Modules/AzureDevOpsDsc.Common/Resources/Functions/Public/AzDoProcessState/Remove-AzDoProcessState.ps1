<#
.SYNOPSIS
Removes a custom workflow state from an Azure DevOps work item type.

.DESCRIPTION
Deletes a custom state. Only custom states can be deleted - an inherited state is part of the
parent process's workflow, and the resource reports that rather than letting the API fail.

Work items sitting in the deleted state are not moved. They keep the value, which then fails
validation the next time they are edited, so removing a state that is in use is worth doing
deliberately.

.PARAMETER ProcessName
The name of the inherited process.

.PARAMETER WorkItemTypeName
The display name of the work item type.

.PARAMETER StateName
The name of the state.

.PARAMETER StateCategory
'Proposed', 'InProgress', 'Resolved', 'Completed' or 'Removed'.

.PARAMETER Color
The hex colour without a leading '#'.

.PARAMETER Order
The position of the state within its category.

.PARAMETER LookupResult
The lookup result supplied by the DSC base class.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.

.EXAMPLE
Remove-AzDoProcessState -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident' -StateName 'Triaged'
#>
Function Remove-AzDoProcessState
{
    [CmdletBinding()]
    [OutputType([System.Object])]
    param
    (
        [Parameter(Mandatory = $true)]
        [Alias('Process')]
        [System.String]$ProcessName,

        [Parameter(Mandatory = $true)]
        [Alias('WorkItemType')]
        [System.String]$WorkItemTypeName,

        [Parameter(Mandatory = $true)]
        [Alias('Name')]
        [System.String]$StateName,

        [Parameter()]
        [System.String]$StateCategory,

        [Parameter()]
        [System.String]$Color,

        [Parameter()]
        [System.Int32]$Order,

        [Parameter()]
        [HashTable]$LookupResult,

        [Parameter()]
        [Ensure]$Ensure,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Remove-AzDoProcessState] Started."

    $OrganizationName = Get-AzDoOrganizationName
    $processId        = $LookupResult.processId
    $refName          = $LookupResult.workItemTypeRefName
    $stateId          = $LookupResult.stateId
    $customization    = $LookupResult.customization

    if ([String]::IsNullOrWhiteSpace($stateId))
    {
        Write-Verbose "[Remove-AzDoProcessState] State '$StateName' does not exist on work item type '$WorkItemTypeName'. Nothing to remove."
        return
    }

    # An inherited state belongs to the parent process's workflow and cannot be deleted from here.
    if ($customization -eq 'system' -or $customization -eq 'inherited')
    {
        Write-Error "[Remove-AzDoProcessState] State '$StateName' is inherited from the parent process and cannot be deleted. Only custom states can be removed."
        return
    }

    Write-Warning "[Remove-AzDoProcessState] Removing state '$StateName' from work item type '$WorkItemTypeName'. Work items currently in this state keep the value, which will then fail validation on their next edit."

    return (Remove-DevOpsProcessState -Organization $OrganizationName -ProcessId $processId `
        -WorkItemTypeRefName $refName -StateId $stateId)
}
