Function Remove-AzDoTeamMember
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter(Mandatory = $true)][string]$TeamName,
        [Parameter(Mandatory = $true)][string]$MemberName,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Remove-AzDoTeamMember] Removing '$MemberName' from team '$TeamName'."

    $OrgName = Get-AzDoOrganizationName
    $teamKey = '{0}\{1}' -f $ProjectName, $TeamName

    # Lookup the team group descriptor from the cache, with live fallback (team may have been
    # created after the cache was built at init).
    $team = Get-CacheItem -Key $teamKey -Type 'LiveTeams'
    if (-not $team)
    {
        $project = Resolve-AzDoProject -ProjectName $ProjectName
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
