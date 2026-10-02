<#
.SYNOPSIS
Retrieves whether an Azure DevOps work item type is associated with a backlog level.

.DESCRIPTION
Resolves the behavior on the process, then checks whether the work item type is associated with it
and whether it is the default type for that level.

Behaviors are matched by display name or reference name, since a configuration is naturally
written with the readable name ('Stories') while the API addresses them by reference name
('System.RequirementBacklogBehavior').

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
Get-AzDoProcessBehavior -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident' -BehaviorName 'Stories'
#>
Function Get-AzDoProcessBehavior
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
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

    Write-Verbose "[Get-AzDoProcessBehavior] Started."

    $OrganizationName = Get-AzDoOrganizationName

    $result = @{
        Ensure            = [Ensure]::Absent
        ProcessName       = $ProcessName
        WorkItemTypeName  = $WorkItemTypeName
        BehaviorName      = $BehaviorName
        propertiesChanged = @()
        status            = $null
        reason            = $null
    }

    $resolved = Resolve-AzDoProcessWorkItemType -Organization $OrganizationName -ProcessName $ProcessName -WorkItemTypeName $WorkItemTypeName

    if (-not $resolved.IsCustomizable -or $null -eq $resolved.WorkItemType)
    {
        Write-Error "[Get-AzDoProcessBehavior] Cannot read behaviors for '$WorkItemTypeName' on process '$ProcessName' ($($resolved.Reason))."
        $result.status = [DSCGetSummaryState]::Error
        $result.reason = $resolved.Reason
        return $result
    }

    $processId = $resolved.Process.id
    $refName   = $resolved.WorkItemType.referenceName

    $result.processId           = $processId
    $result.workItemTypeRefName = $refName

    # Behaviors are process-scoped; the association is per work item type.
    $behaviors = List-DevOpsProcessBehaviors -Organization $OrganizationName -ProcessId $processId

    $behavior = $behaviors | Where-Object {
        ($_.name -eq $BehaviorName) -or ($_.referenceName -eq $BehaviorName) -or ($_.id -eq $BehaviorName)
    } | Select-Object -First 1

    if ($null -eq $behavior)
    {
        Write-Error "[Get-AzDoProcessBehavior] Behavior '$BehaviorName' does not exist on process '$ProcessName'. Behaviors are the backlog levels the process exposes."
        $result.status = [DSCGetSummaryState]::Error
        $result.reason = 'BehaviorNotFound'
        return $result
    }

    $behaviorRefName = if ($behavior.referenceName) { $behavior.referenceName } else { $behavior.id }
    $result.behaviorRefName = $behaviorRefName

    $associations = List-DevOpsWorkItemTypeBehaviors -Organization $OrganizationName -ProcessId $processId -WorkItemTypeRefName $refName

    $association = $associations | Where-Object {
        ($_.behavior.id -eq $behaviorRefName) -or ($_.behavior.referenceName -eq $behaviorRefName)
    } | Select-Object -First 1

    if ($null -eq $association)
    {
        Write-Verbose "[Get-AzDoProcessBehavior] Work item type '$WorkItemTypeName' is not on backlog level '$BehaviorName'."
        $result.status = [DSCGetSummaryState]::NotFound
        return $result
    }

    $result.liveCache = $association
    $result.Ensure    = [Ensure]::Present

    $propertiesChanged = @()

    if ($PSBoundParameters.ContainsKey('IsDefault'))
    {
        if ([bool]$association.isDefault -ne $IsDefault)
        {
            Write-Verbose "[Get-AzDoProcessBehavior] IsDefault differs for '$WorkItemTypeName' on '$BehaviorName'."
            $propertiesChanged += 'IsDefault'
        }
    }

    $result.propertiesChanged = $propertiesChanged
    $result.status = if ($propertiesChanged.Count -gt 0) { [DSCGetSummaryState]::Changed } else { [DSCGetSummaryState]::Unchanged }

    Write-Verbose "[Get-AzDoProcessBehavior] '$WorkItemTypeName' on '$BehaviorName' status: $($result.status)."

    return $result
}
