<#
.SYNOPSIS
    DSC resource for managing Azure DevOps project teams.
.DESCRIPTION
    This resource manages teams within Azure DevOps projects. Teams group users together and can be
    assigned area paths and iterations for work item organization. Team members can be managed
    separately using the AzDoTeamMember resource.

.PARAMETER ProjectName
    The name of the Azure DevOps project. This property is mandatory and serves as a key property for the resource.

.PARAMETER TeamName
    The name of the team. This is a key property.

.PARAMETER Description
    An optional description for the team.

#>
[DscResource()]
class AzDoTeam : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)][System.String]$ProjectName
    [DscProperty(Mandatory)][System.String]$TeamName
    [DscProperty()][System.String]$Description

    AzDoTeam() { $this.Construct() }
    [void] Set() { ([AzDevOpsDscResourceBase]$this).Set() }
    [System.Boolean] Test() { return ([AzDevOpsDscResourceBase]$this).Test() }
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
