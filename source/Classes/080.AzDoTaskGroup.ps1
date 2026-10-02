<#
.SYNOPSIS
    DSC resource for managing Azure DevOps reusable task groups.
.DESCRIPTION
    This resource manages task groups in Azure DevOps, which are reusable collections of pipeline
    tasks that can be shared across multiple pipelines. Task groups help enforce consistent build
    and deployment processes.

.PARAMETER ProjectName
    The name of the Azure DevOps project. This property is mandatory and serves as a key property for the resource.

.PARAMETER TaskGroupName
    The name of the task group. This is a key property.

.PARAMETER Description
    An optional description for the task group.

.PARAMETER Category
    The category of the task group (e.g., Build, Deploy, Test).

#>

[DscResource()]
class AzDoTaskGroup : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)]
    [System.String]$ProjectName

    [DscProperty(Mandatory)]
    [System.String]$TaskGroupName

    [DscProperty()]
    [System.String]$Description

    [DscProperty()]
    [System.String]$Category

    [DscProperty()]
    [HashTable[]]$Tasks

    [DscProperty()]
    [HashTable[]]$Inputs

    AzDoTaskGroup()
    {
        $this.Construct()
    }

    [void] Set() { ([AzDevOpsDscResourceBase]$this).Set() }
    [System.Boolean] Test() { return ([AzDevOpsDscResourceBase]$this).Test() }
    [AzDoTaskGroup] Get()
    {
        return [AzDoTaskGroup]$($this.GetDscCurrentStateProperties())
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

        if ($null -eq $CurrentResourceObject)
        {
            return $properties
        }

        $properties.ProjectName    = $CurrentResourceObject.ProjectName
        $properties.TaskGroupName  = $CurrentResourceObject.TaskGroupName
        $properties.Description    = $CurrentResourceObject.Description
        $properties.Category       = $CurrentResourceObject.Category
        $properties.Tasks          = $CurrentResourceObject.Tasks
        $properties.Inputs         = $CurrentResourceObject.Inputs
        $properties.LookupResult   = $CurrentResourceObject.LookupResult
        $properties.Ensure         = $CurrentResourceObject.Ensure

        Write-Verbose "[AzDoTaskGroup] Current state properties: $($properties | Out-String)"

        return $properties
    }
}
