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

.PARAMETER IsTeamAdmin
    Whether the member should hold team administrator rights (manage team membership, board columns,
    card rules, backlog settings and dashboards). This property is optional; when it is not set on
    the configuration, the member's team-administrator state is left untouched and defaults to
    $false when the member is newly added. Team administrator rights are implemented as an Access
    Control Entry the member holds in the 'Identity' security namespace on the team's own token,
    which is the same mechanism the Azure DevOps portal's "Administrators" list uses.

#>
[DscResource()]
class AzDoTeamMember : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)][System.String]$ProjectName
    [DscProperty(Mandatory)][System.String]$TeamName
    [DscProperty(Mandatory)][System.String]$MemberName
    [DscProperty()][System.Boolean]$IsTeamAdmin

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
        $properties.IsTeamAdmin  = $CurrentResourceObject.IsTeamAdmin
        $properties.LookupResult = $CurrentResourceObject.LookupResult
        $properties.Ensure       = $CurrentResourceObject.Ensure
        return $properties
    }
}
