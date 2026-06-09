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

    $team   = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $TeamName) -Type 'LiveTeams'
    $member = Get-CacheItem -Key ('[{0}]\{1}' -f $ProjectName, $MemberName) -Type 'LiveGroups'

    if (-not $member)
    {
        $member = Get-CacheItem -Key $MemberName -Type 'LiveUsers'
    }

    if ((-not $team) -or (-not $member))
    {
        Write-Error "[Remove-AzDoTeamMember] Team or member not found in cache."
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
