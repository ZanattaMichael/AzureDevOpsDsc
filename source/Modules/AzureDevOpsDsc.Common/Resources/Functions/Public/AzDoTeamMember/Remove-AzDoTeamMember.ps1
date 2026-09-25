<#
.SYNOPSIS
Removes a member from an Azure DevOps team, revoking any team administrator rights it holds.

.DESCRIPTION
The Remove-AzDoTeamMember function removes the specified user or group from the team's membership
group. Before doing so, it best-effort revokes the member's 'ManageMembership' Access Control
Entry on the team's own token in the 'Identity' security namespace, so a removed member does not
retain team administrator rights it can no longer be seen to hold in the team's own membership UI.
This revoke is attempted regardless of whether IsTeamAdmin was ever set to $true, and a failure to
revoke it does not block the membership removal.

.PARAMETER ProjectName
The name of the Azure DevOps project. This parameter is mandatory.

.PARAMETER TeamName
The name of the team to remove the member from. This parameter is mandatory.

.PARAMETER MemberName
The UPN, display name, or email of the user or group to remove. This parameter is mandatory.

.PARAMETER IsTeamAdmin
Supplied by the DSC base class; not used to gate the revoke, which always runs on removal.

.PARAMETER LookupResult
A hashtable representing the lookup result. This parameter is optional.

.PARAMETER Ensure
Specifies the desired state of the team member. This parameter is optional.

.PARAMETER Force
A switch parameter to force the operation. This parameter is optional.

.EXAMPLE
Remove-AzDoTeamMember -ProjectName 'Contoso' -TeamName 'Alpha' -MemberName 'jdoe@contoso.com'

#>
Function Remove-AzDoTeamMember
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

    Write-Verbose "[Remove-AzDoTeamMember] Removing '$MemberName' from team '$TeamName'."

    $OrgName = Get-AzDoOrganizationName
    $teamKey = '{0}\{1}' -f $ProjectName, $TeamName

    # The project is needed as the first half of the Identity ACL token when revoking the
    # team-administrator ACE below, so resolve it up front rather than only on a cache miss.
    $project = Resolve-AzDoProject -ProjectName $ProjectName

    # Lookup the team group descriptor from the cache, with live fallback (team may have been
    # created after the cache was built at init).
    $team = Get-CacheItem -Key $teamKey -Type 'LiveTeams'
    if (-not $team)
    {
        if ($project)
        {
            $allTeams = List-DevOpsTeams -ApiUri "https://dev.azure.com/$OrgName" -ProjectId $project.id
            $team = $allTeams | Where-Object { $_.name -eq $TeamName } | Select-Object -First 1
            if ($team)
            {
                $descriptor = Get-DevOpsSecurityDescriptor -ProjectId $team.id -Organization $OrgName
                if ($descriptor) { $team | Add-Member -NotePropertyName 'descriptor' -NotePropertyValue $descriptor -Force }
                Add-CacheItem -Key $teamKey -Value $team -Type 'LiveTeams'
            }
        }
    }

    # $MemberName is already fully qualified (e.g. "[ProjectName]\GroupName") — look up directly.
    $member = Get-CacheItem -Key $MemberName -Type 'LiveGroups'
    if (-not $member) { $member = Get-CacheItem -Key $MemberName -Type 'LiveUsers' }
    if (-not $member)
    {
        # Fall back to Find-AzDoIdentity which has live API lookups for both groups and users.
        $member = Find-AzDoIdentity -Identity $MemberName
    }

    if ((-not $team) -or (-not $member))
    {
        # Team or member already absent — nothing to remove (desired state achieved).
        Write-Verbose "[Remove-AzDoTeamMember] Team or member not found; treating as already absent."
        return
    }

    # Best-effort revoke of any team-administrator ACE the member holds before removing membership,
    # so a removed member does not retain admin rights it can no longer be seen to hold in the
    # team's own membership UI. This always runs on removal, regardless of the IsTeamAdmin value
    # supplied, and a failure here does not block the membership removal itself.
    try
    {
        $memberAclDescriptor = $null
        if ($member.ACLIdentity -and $member.ACLIdentity.descriptor)
        {
            $memberAclDescriptor = $member.ACLIdentity.descriptor
        }
        elseif ($member.descriptor)
        {
            $memberAclDescriptor = (Get-DevOpsDescriptorIdentity -OrganizationName $OrgName -SubjectDescriptor $member.descriptor).descriptor
        }

        if ($project -and $team -and $memberAclDescriptor)
        {
            Set-DevOpsTeamAdministrator -OrganizationName $OrgName -ProjectId $project.id -TeamId $team.id -MemberDescriptor $memberAclDescriptor -IsTeamAdmin $false
        }
    }
    catch
    {
        Write-Warning "[Remove-AzDoTeamMember] Failed to revoke team-administrator rights for '$MemberName' on team '$TeamName': $_"
    }

    $params = @{
        ApiUri           = 'https://vssps.dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
        MemberDescriptor = $member.descriptor
        GroupDescriptor  = $team.descriptor
    }

    Remove-DevOpsTeamMember @params

    $cacheKey = '{0}\{1}\{2}' -f $ProjectName, $TeamName, $MemberName
    Remove-CacheItem -Key $cacheKey -Type 'LiveTeamMembers'
    Export-CacheObject -CacheType 'LiveTeamMembers' -Content $AzDoLiveTeamMembers
    Write-Verbose "[Remove-AzDoTeamMember] '$MemberName' removed from team '$TeamName'."
}
