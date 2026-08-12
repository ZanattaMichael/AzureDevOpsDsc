<#
.SYNOPSIS
    DSC resource for managing Azure DevOps team membership.
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
