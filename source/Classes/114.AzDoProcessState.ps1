<#
.SYNOPSIS
    DSC resource for managing workflow states on a work item type of an Azure DevOps inherited process.

.DESCRIPTION
    Manages a custom workflow state on a work item type - its category, colour and order.

.NOTES
    Author: Michael Zanatta

    The state category matters more than the state name. Boards, cumulative flow diagrams and the
    Analytics service all reason about categories ('Proposed', 'InProgress', 'Resolved',
    'Completed', 'Removed'), not about what a state is called, so a state in the wrong category
    reports correctly in the UI and wrongly in every metric.

    A state's category cannot be changed after creation. Moving a state between categories would
    reclassify every work item currently in it, so the API refuses, and this resource reports the
    mismatch rather than recreating the state - which would strand those work items.

    Only custom states can be removed. Work items sitting in a deleted state are not moved: they
    keep the value, which then fails validation on their next edit.

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

.INPUTS
    None

.OUTPUTS
    None

.EXAMPLE
    AzDoProcessState Triaged
    {
        ProcessName      = 'Contoso Agile'
        WorkItemTypeName = 'Incident'
        StateName        = 'Triaged'
        StateCategory    = 'InProgress'
        Color            = '007ACC'
        Ensure           = 'Present'
    }
#>

[DscResource()]
class AzDoProcessState : AzDevOpsDscResourceBase
{
    [DscProperty(Mandatory)]
    [Alias('Process')]
    [System.String]$ProcessName

    [DscProperty(Mandatory)]
    [Alias('WorkItemType')]
    [System.String]$WorkItemTypeName

    [DscProperty(Key, Mandatory)]
    [Alias('Name')]
    [System.String]$StateName

    [DscProperty()]
    [ValidateSet('Proposed', 'InProgress', 'Resolved', 'Completed', 'Removed')]
    [System.String]$StateCategory = 'InProgress'

    [DscProperty()]
    [System.String]$Color

    [DscProperty()]
    [System.Int32]$Order = 0

    AzDoProcessState()
    {
        $this.Construct()
    }

    [void] Set() { ([AzDevOpsDscResourceBase]$this).Set() }
    [System.Boolean] Test() { return ([AzDevOpsDscResourceBase]$this).Test() }
    [AzDoProcessState] Get()
    {
        return [AzDoProcessState]$($this.GetDscCurrentStateProperties())
    }

    hidden [System.String[]]GetDscResourcePropertyNamesWithNoSetSupport()
    {
        return @()
    }

    hidden [Hashtable]GetDscCurrentStateProperties([PSCustomObject]$CurrentResourceObject)
    {
        $properties = @{
            Ensure = [Ensure]::Absent
        }

        # If the resource object is null, return the properties
        if ($null -eq $CurrentResourceObject)
        {
            return $properties
        }

        $properties.ProcessName      = $CurrentResourceObject.ProcessName
        $properties.WorkItemTypeName = $CurrentResourceObject.WorkItemTypeName
        $properties.StateName        = $CurrentResourceObject.StateName
        $properties.StateCategory    = $CurrentResourceObject.StateCategory
        $properties.Color            = $CurrentResourceObject.Color
        $properties.Order            = $CurrentResourceObject.Order
        $properties.LookupResult     = $CurrentResourceObject.LookupResult
        $properties.Ensure           = $CurrentResourceObject.Ensure

        Write-Verbose "[AzDoProcessState] Current state properties: $($properties | Out-String)"

        return $properties
    }
}
