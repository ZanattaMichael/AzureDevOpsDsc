<#
.SYNOPSIS
    DSC resource for managing Azure DevOps project teams.
#>
[DscResource()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCStandardDSCFunctionsInResource', '', Justification='Test() and Set() method are inherited from base, "AzDevOpsDscResourceBase" class')]
class AzDoTeam : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)][System.String]$ProjectName
    [DscProperty(Mandatory)][System.String]$TeamName
    [DscProperty()][System.String]$Description

    AzDoTeam() { $this.Construct() }
    [AzDoTeam] Get() { return [AzDoTeam]$($this.GetDscCurrentStateProperties()) }
    hidden [System.String[]]GetDscResourcePropertyNamesWithNoSetSupport() { return @() }
    hidden [Hashtable]GetDscCurrentStateProperties([PSCustomObject]$CurrentResourceObject) {
        $properties = @{ Ensure=[Ensure]::Absent }
        if ($null -eq $CurrentResourceObject) { return $properties }
        $properties.ProjectName  = $CurrentResourceObject.ProjectName
        $properties.TeamName     = $CurrentResourceObject.TeamName
        $properties.Description  = $CurrentResourceObject.Description
        $properties.LookupResult = $CurrentResourceObject.LookupResult
        $properties.Ensure       = $CurrentResourceObject.Ensure
        return $properties
    }
}