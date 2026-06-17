<#
.SYNOPSIS
    DSC resource for managing Azure DevOps team membership.
#>
[DscResource()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCStandardDSCFunctionsInResource', '', Justification='Test() and Set() method are inherited from base, "AzDevOpsDscResourceBase" class')]
class AzDoTeamMember : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)][System.String]$ProjectName
    [DscProperty(Mandatory)][System.String]$TeamName
    [DscProperty(Mandatory)][System.String]$MemberName

    AzDoTeamMember() { $this.Construct() }
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