<#
.SYNOPSIS
    DSC resource associating a work item type with a backlog level on an Azure DevOps inherited process.

.DESCRIPTION
    Manages the behavior association that puts a work item type on a backlog.

.NOTES
    Author: Michael Zanatta

    This is usually the missing step when a newly created custom work item type appears to do
    nothing: the type exists, but until it is associated with a behavior it shows up on no backlog
    and no board. Creating a type with AzDoProcessWorkItemType and stopping there leaves it
    invisible to the people meant to use it.

    Behaviors are process-scoped - they are the backlog levels the process exposes (Epics,
    Features, Stories, Tasks) - while the association is per work item type, which is what this
    resource manages.

    Removing an association takes the type off that backlog. The work item type and its work items
    are untouched.

.PARAMETER ProcessName
    The name of the inherited process.

.PARAMETER WorkItemTypeName
    The display name of the work item type.

.PARAMETER BehaviorName
    The name or reference name of the behavior, for example 'Stories' or
    'System.RequirementBacklogBehavior'.

.PARAMETER IsDefault
    Whether this work item type is the default for creating new items at that backlog level.

.INPUTS
    None

.OUTPUTS
    None

.EXAMPLE
    AzDoProcessBehavior IncidentOnRequirements
    {
        ProcessName      = 'Contoso Agile'
        WorkItemTypeName = 'Incident'
        BehaviorName     = 'Stories'
        Ensure           = 'Present'
    }
#>

[DscResource()]
class AzDoProcessBehavior : AzDevOpsDscResourceBase
{
    [DscProperty(Mandatory)]
    [Alias('Process')]
    [System.String]$ProcessName

    [DscProperty(Mandatory)]
    [Alias('WorkItemType')]
    [System.String]$WorkItemTypeName

    [DscProperty(Key, Mandatory)]
    [Alias('Name')]
    [System.String]$BehaviorName

    [DscProperty()]
    [System.Boolean]$IsDefault = $false

    AzDoProcessBehavior()
    {
        $this.Construct()
    }

    [void] Set() { ([AzDevOpsDscResourceBase]$this).Set() }
    [System.Boolean] Test() { return ([AzDevOpsDscResourceBase]$this).Test() }
    [AzDoProcessBehavior] Get()
    {
        return [AzDoProcessBehavior]$($this.GetDscCurrentStateProperties())
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
        $properties.BehaviorName     = $CurrentResourceObject.BehaviorName
        $properties.IsDefault        = $CurrentResourceObject.IsDefault
        $properties.LookupResult     = $CurrentResourceObject.LookupResult
        $properties.Ensure           = $CurrentResourceObject.Ensure

        Write-Verbose "[AzDoProcessBehavior] Current state properties: $($properties | Out-String)"

        return $properties
    }
}
