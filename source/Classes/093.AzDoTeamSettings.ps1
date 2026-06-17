<#
.SYNOPSIS
    DSC resource for managing the iteration and area-path configuration of an Azure DevOps team.
.DESCRIPTION
    Allows the iteration paths (default iteration, backlog iteration and the iterations assigned to
    the team) and the area paths (default area path and the team's area paths) to be declared as
    part of how a team is configured.
#>
[DscResource()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCStandardDSCFunctionsInResource', '', Justification='Test() and Set() method are inherited from base, "AzDevOpsDscResourceBase" class')]
class AzDoTeamSettings : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)][System.String]$ProjectName
    [DscProperty(Key, Mandatory)][System.String]$TeamName
    [DscProperty()][System.String]$BacklogIterationPath
    [DscProperty()][System.String]$DefaultIterationPath
    [DscProperty()][System.String[]]$IterationPaths
    [DscProperty()][System.String]$DefaultAreaPath
    [DscProperty()][System.String[]]$AreaPaths
    [DscProperty()][System.String[]]$WorkingDays
    [DscProperty()][ValidateSet('asRequirements', 'asTasks', 'off')][System.String]$BugsBehavior

    AzDoTeamSettings() { $this.Construct() }
    [AzDoTeamSettings] Get() { return [AzDoTeamSettings]$($this.GetDscCurrentStateProperties()) }
    hidden [System.String[]]GetDscResourcePropertyNamesWithNoSetSupport() { return @() }
    hidden [Hashtable]GetDscCurrentStateProperties([PSCustomObject]$CurrentResourceObject) {
        $properties = @{ Ensure = [Ensure]::Absent }
        if ($null -eq $CurrentResourceObject) { return $properties }
        $properties.ProjectName          = $CurrentResourceObject.ProjectName
        $properties.TeamName             = $CurrentResourceObject.TeamName
        $properties.BacklogIterationPath = $CurrentResourceObject.BacklogIterationPath
        $properties.DefaultIterationPath = $CurrentResourceObject.DefaultIterationPath
        $properties.IterationPaths       = $CurrentResourceObject.IterationPaths
        $properties.DefaultAreaPath      = $CurrentResourceObject.DefaultAreaPath
        $properties.AreaPaths            = $CurrentResourceObject.AreaPaths
        $properties.WorkingDays          = $CurrentResourceObject.WorkingDays
        $properties.BugsBehavior         = $CurrentResourceObject.BugsBehavior
        $properties.LookupResult         = $CurrentResourceObject.LookupResult
        $properties.Ensure               = $CurrentResourceObject.Ensure
        return $properties
    }
}
