Function New-AzDoTeamMember
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

    Write-Verbose "[New-AzDoTeamMember] Adding '$MemberName' to team '$TeamName'."

    $OrgName  = Get-AzDoOrganizationName
    $teamKey  = '{0}\{1}' -f $ProjectName, $TeamName

    # Lookup the team group descriptor from the cache, with live fallback
    $team = Get-CacheItem -Key $teamKey -Type 'LiveTeams'
    if (-not $team)
    {
        Write-Verbose "[New-AzDoTeamMember] Team '$TeamName' not in cache — falling back to live API lookup."
        $project = Get-CacheItem -Key $ProjectName -Type 'LiveProjects'
        if (-not $project)
        {
            $project = Invoke-AzDevOpsApiRestMethod -Uri "https://dev.azure.com/$OrgName/_apis/projects/${ProjectName}?api-version=7.1-preview.4" -Method Get
            if ($project) { Add-CacheItem -Key $ProjectName -Value $project -Type 'LiveProjects' }
        }
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
    if (-not $member)
    {
        # Try as a user (principal name)
        $member = Get-CacheItem -Key $MemberName -Type 'LiveUsers'
    }
    if (-not $member)
    {
        # Fall back to Find-AzDoIdentity which has live API lookups for both groups and users
        $member = Find-AzDoIdentity -Identity $MemberName
    }

    if ((-not $team) -or (-not $member))
    {
        Write-Error "[New-AzDoTeamMember] Team or member not found in cache."
        return
    }

    $params = @{
        ApiUri           = 'https://vssps.dev.azure.com/{0}/' -f $OrgName
        MemberDescriptor = $member.descriptor
        GroupDescriptor  = $team.descriptor
    }

    New-DevOpsTeamMember @params

    $cacheKey = '{0}\{1}\{2}' -f $ProjectName, $TeamName, $MemberName
    Add-CacheItem -Key $cacheKey -Value $member -Type 'LiveTeamMembers'
    Export-CacheObject -CacheType 'LiveTeamMembers' -Content $AzDoLiveTeamMembers
    Write-Verbose "[New-AzDoTeamMember] '$MemberName' added to team '$TeamName'."
}
