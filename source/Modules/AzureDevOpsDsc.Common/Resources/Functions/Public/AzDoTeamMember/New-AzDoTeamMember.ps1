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

    # Lookup the team group descriptor from the cache
    $team   = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $TeamName) -Type 'LiveTeams'
    # $MemberName is already fully qualified (e.g. "[ProjectName]\GroupName") — look up directly.
    $member = Get-CacheItem -Key $MemberName -Type 'LiveGroups'

    if (-not $member)
    {
        # Try as a user (principal name)
        $member = Get-CacheItem -Key $MemberName -Type 'LiveUsers'
    }

    if ((-not $team) -or (-not $member))
    {
        Write-Error "[New-AzDoTeamMember] Team or member not found in cache."
        return
    }

    $params = @{
        ApiUri           = 'https://vssps.dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
        MemberDescriptor = $member.descriptor
        GroupDescriptor  = $team.descriptor
    }

    New-DevOpsTeamMember @params

    $cacheKey = '{0}\{1}\{2}' -f $ProjectName, $TeamName, $MemberName
    Add-CacheItem -Key $cacheKey -Value $member -Type 'LiveTeamMembers'
    Export-CacheObject -CacheType 'LiveTeamMembers' -Content $AzDoLiveTeamMembers
    Write-Verbose "[New-AzDoTeamMember] '$MemberName' added to team '$TeamName'."
}
