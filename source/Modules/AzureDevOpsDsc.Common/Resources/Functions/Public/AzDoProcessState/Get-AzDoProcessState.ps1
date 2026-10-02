<#
.SYNOPSIS
Retrieves the current state of a workflow state on an Azure DevOps work item type.

.DESCRIPTION
Resolves the process and work item type, finds the state and compares its colour and order against
the desired state.

A category mismatch is reported as an error rather than as drift. A state's category cannot be
changed after creation - the API refuses, because moving a state between categories would
reclassify every work item currently in it - and recreating the state to force it would strand
those work items.

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
Get-AzDoProcessState -ProcessName 'Contoso Agile' -WorkItemTypeName 'Incident' -StateName 'Triaged' -StateCategory 'InProgress'
#>
Function Get-AzDoProcessState
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

    Write-Verbose "[Get-AzDoProcessState] Started."

    $OrganizationName = Get-AzDoOrganizationName

    $result = @{
        Ensure            = [Ensure]::Absent
        ProcessName       = $ProcessName
        WorkItemTypeName  = $WorkItemTypeName
        StateName         = $StateName
        propertiesChanged = @()
        status            = $null
        reason            = $null
    }

    $resolved = Resolve-AzDoProcessWorkItemType -Organization $OrganizationName -ProcessName $ProcessName -WorkItemTypeName $WorkItemTypeName

    if (-not $resolved.IsCustomizable -or $null -eq $resolved.WorkItemType)
    {
        Write-Error "[Get-AzDoProcessState] Cannot read states for '$WorkItemTypeName' on process '$ProcessName' ($($resolved.Reason))."
        $result.status = [DSCGetSummaryState]::Error
        $result.reason = $resolved.Reason
        return $result
    }

    $processId = $resolved.Process.id
    $refName   = $resolved.WorkItemType.referenceName

    $result.processId           = $processId
    $result.workItemTypeRefName = $refName

    $states = List-DevOpsProcessStates -Organization $OrganizationName -ProcessId $processId -WorkItemTypeRefName $refName
    $state  = $states | Where-Object { $_.name -eq $StateName } | Select-Object -First 1

    if ($null -eq $state)
    {
        Write-Verbose "[Get-AzDoProcessState] State '$StateName' does not exist on work item type '$WorkItemTypeName'."
        $result.status = [DSCGetSummaryState]::NotFound
        return $result
    }

    $result.stateId       = $state.id
    $result.customization = $state.customizationType
    $result.liveCache     = $state
    $result.Ensure        = [Ensure]::Present

    # The category is fixed at creation. Report the mismatch rather than attempting a recreate,
    # which would strand every work item currently sitting in this state.
    if ((-not [String]::IsNullOrWhiteSpace($StateCategory)) -and ($state.stateCategory -ne $StateCategory))
    {
        Write-Error "[Get-AzDoProcessState] State '$StateName' is in category '$($state.stateCategory)' but the configuration asks for '$StateCategory'. A state's category cannot be changed after creation - create a new state in the target category and migrate the work items."
        $result.status = [DSCGetSummaryState]::Error
        $result.reason = 'StateCategoryImmutable'
        return $result
    }

    $propertiesChanged = @()

    if ($PSBoundParameters.ContainsKey('Color') -and (-not [String]::IsNullOrWhiteSpace($Color)))
    {
        $desiredColor = $Color.TrimStart('#')
        $currentColor = "$($state.color)".TrimStart('#')

        if ($desiredColor -ne $currentColor)
        {
            Write-Verbose "[Get-AzDoProcessState] Color differs for state '$StateName'."
            $propertiesChanged += 'Color'
        }
    }

    if ($PSBoundParameters.ContainsKey('Order'))
    {
        if ([int]$state.order -ne $Order)
        {
            Write-Verbose "[Get-AzDoProcessState] Order differs for state '$StateName'."
            $propertiesChanged += 'Order'
        }
    }

    $result.propertiesChanged = $propertiesChanged
    $result.status = if ($propertiesChanged.Count -gt 0) { [DSCGetSummaryState]::Changed } else { [DSCGetSummaryState]::Unchanged }

    Write-Verbose "[Get-AzDoProcessState] State '$StateName' status: $($result.status)."

    return $result
}
