<#
.SYNOPSIS
    DSC resource for managing Azure DevOps reusable task groups.
#>

[DscResource()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCStandardDSCFunctionsInResource', '', Justification='Test() and Set() method are inherited from base, "AzDevOpsDscResourceBase" class')]
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