<#
.SYNOPSIS
    DSC resource for managing Azure DevOps team membership.
.DESCRIPTION
    This resource manages membership of individual users or groups within a team. The team must
    already exist — use the AzDoTeam resource to create it first.

.PARAMETER ProjectName
    The name of the Azure DevOps project. This property is mandatory and serves as a key property for the resource.

.PARAMETER TeamName
    The name of the team. This is a key property.

.PARAMETER MemberName
    The UPN, display name, or email of the user or group to add as a team member. This is a key property.

#>
[DscResource()]
class AzDoTeamMember : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)][System.String]$ProjectName
    [DscProperty(Mandatory)][System.String]$TeamName
    [DscProperty(Mandatory)][System.String]$MemberName

    AzDoTeamMember() { $this.Construct() }
    [void] Set() { ([AzDevOpsDscResourceBase]$this).Set() }
    [System.Boolean] Test() { return ([AzDevOpsDscResourceBase]$this).Test() }
    [AzDoTeamMember] Get() { return [AzDoTeamMember]$($this.GetDscCurrentStateProperties()) }
    hidden [System.String[]]GetDscResourcePropertyNamesWithNoSetSupport() { return @() }
    hidden [Hashtable]GetDscCurrentStateProperties([PSCustomObject]$CurrentResourceObject) {
        $properties = @{ Ensure=[Ensure]::Absent }
        if ($null -eq $CurrentResourceObject) { return $properties }
        $properties.ProjectName  = $CurrentResourceObject.ProjectName
        $properties.TeamName     = $CurrentResourceObject.TeamName
        $properties.MemberName   = $CurrentResourceObject.MemberName
        $properties.LookupResult = $CurrentResourceObject.LookupResult
        $properties.Ensure       = $CurrentResourceObject.Ensure
        return $properties
    }
}
