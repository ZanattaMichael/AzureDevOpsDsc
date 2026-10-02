<#
.SYNOPSIS
Applies the desired team membership and team-administrator state for an Azure DevOps team member.

.DESCRIPTION
Team membership itself is add/remove only, so Set-AzDoTeamMember delegates to New-AzDoTeamMember,
which is idempotent for membership and also applies the IsTeamAdmin Access Control Entry when that
property is bound.

.PARAMETER ProjectName
The name of the Azure DevOps project. This parameter is mandatory.

.PARAMETER TeamName
The name of the team. This parameter is mandatory.

.PARAMETER MemberName
The UPN, display name, or email of the user or group. This parameter is mandatory.

.PARAMETER IsTeamAdmin
Whether the member should hold team administrator rights. This parameter is optional.

.PARAMETER LookupResult
A hashtable representing the lookup result. This parameter is optional.

.PARAMETER Ensure
Specifies the desired state of the team member. This parameter is optional.

.PARAMETER Force
A switch parameter to force the operation. This parameter is optional.

.EXAMPLE
Set-AzDoTeamMember -ProjectName 'Contoso' -TeamName 'Alpha' -MemberName 'jdoe@contoso.com' -IsTeamAdmin $true

#>
Function Set-AzDoTeamMember
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter(Mandatory = $true)][string]$TeamName,
        [Parameter(Mandatory = $true)][string]$MemberName,
        [Parameter()][System.Boolean]$IsTeamAdmin,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )

    # Team membership is add/remove only — Set behaves the same as New, which also applies
    # IsTeamAdmin when bound.
    Write-Verbose "[Set-AzDoTeamMember] Team membership has no update semantics. Delegating to New-AzDoTeamMember."
    New-AzDoTeamMember @PSBoundParameters
}
