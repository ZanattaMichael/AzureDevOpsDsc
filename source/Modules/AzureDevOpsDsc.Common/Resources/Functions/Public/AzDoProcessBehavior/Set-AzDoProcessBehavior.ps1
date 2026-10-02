<#
.SYNOPSIS
Associates an Azure DevOps work item type with a backlog level.

.DESCRIPTION
Adds the behavior association that puts the work item type on a backlog.

This is usually the missing step when a newly created custom work item type appears to do nothing:
the type exists, but without a behavior association it shows up on no backlog and no board.

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
Set-AzDoProcessBehavior -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident' -BehaviorName 'Stories'
#>
Function Set-AzDoProcessBehavior
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

    Write-Verbose "[Set-AzDoProcessBehavior] Started."

    if ($LookupResult.reason -eq 'BehaviorNotFound')
    {
        Write-Error "[Set-AzDoProcessBehavior] Behavior '$BehaviorName' does not exist on process '$ProcessName'. No change was made."
        return
    }

    $OrganizationName = Get-AzDoOrganizationName
    $processId        = $LookupResult.processId
    $refName          = $LookupResult.workItemTypeRefName
    $behaviorRefName  = $LookupResult.behaviorRefName

    if ([String]::IsNullOrWhiteSpace($behaviorRefName) -or [String]::IsNullOrWhiteSpace($refName))
    {
        Write-Error "[Set-AzDoProcessBehavior] Could not resolve work item type '$WorkItemTypeName' or behavior '$BehaviorName' on process '$ProcessName'."
        return
    }

    Write-Verbose "[Set-AzDoProcessBehavior] Associating '$WorkItemTypeName' with backlog level '$BehaviorName'."

    return (Add-DevOpsWorkItemTypeBehavior -Organization $OrganizationName -ProcessId $processId `
        -WorkItemTypeRefName $refName -BehaviorRefName $behaviorRefName -IsDefault ([bool]$IsDefault))
}
