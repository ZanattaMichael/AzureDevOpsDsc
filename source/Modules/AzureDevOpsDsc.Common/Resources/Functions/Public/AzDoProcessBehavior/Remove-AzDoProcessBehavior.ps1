<#
.SYNOPSIS
Removes an Azure DevOps work item type from a backlog level.

.DESCRIPTION
Removes the behavior association, so the work item type no longer appears on that backlog. The
work item type and its work items are untouched - only their presence on the backlog changes,
which makes this reversible by re-adding the association.

.PARAMETER ProcessName
The name of the inherited process.

.PARAMETER WorkItemTypeName
The display name of the work item type.

.PARAMETER BehaviorName
The name or reference name of the behavior (backlog level).

.PARAMETER IsDefault
Whether this work item type is the default for creating new items at that backlog level.

.PARAMETER LookupResult
The lookup result supplied by the DSC base class.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.

.EXAMPLE
Remove-AzDoProcessBehavior -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident' -BehaviorName 'Stories'
#>
Function Remove-AzDoProcessBehavior
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
        [System.String]$BehaviorName,

        [Parameter()]
        [System.Boolean]$IsDefault,

        [Parameter()]
        [HashTable]$LookupResult,

        [Parameter()]
        [Ensure]$Ensure,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Remove-AzDoProcessBehavior] Started."

    $OrganizationName = Get-AzDoOrganizationName
    $processId        = $LookupResult.processId
    $refName          = $LookupResult.workItemTypeRefName
    $behaviorRefName  = $LookupResult.behaviorRefName

    if ([String]::IsNullOrWhiteSpace($behaviorRefName) -or [String]::IsNullOrWhiteSpace($refName))
    {
        Write-Verbose "[Remove-AzDoProcessBehavior] No association between '$WorkItemTypeName' and '$BehaviorName' was resolved. Nothing to remove."
        return
    }

    Write-Verbose "[Remove-AzDoProcessBehavior] Removing '$WorkItemTypeName' from backlog level '$BehaviorName'."

    return (Remove-DevOpsWorkItemTypeBehavior -Organization $OrganizationName -ProcessId $processId `
        -WorkItemTypeRefName $refName -BehaviorRefName $behaviorRefName)
}
