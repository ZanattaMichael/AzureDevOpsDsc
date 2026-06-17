Function Get-AzDoTeamMember
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param (
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter(Mandatory = $true)][string]$TeamName,
        [Parameter(Mandatory = $true)][string]$MemberName,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Get-AzDoTeamMember] Started."

    $result = @{
        Ensure            = [Ensure]::Absent
        propertiesChanged = @()
        status            = $null
    }

    # The member key format is: ProjectName\TeamName\MemberName
    $cacheKey = '{0}\{1}\{2}' -f $ProjectName, $TeamName, $MemberName
    $member = Get-CacheItem -Key $cacheKey -Type 'LiveTeamMembers'

    if ($member)
    {
        Write-Verbose "[Get-AzDoTeamMember] Member '$MemberName' found in team '$TeamName'."
        $result.liveCache = $member
        $result.status    = [DSCGetSummaryState]::Unchanged
    }
    else
    {
        Write-Verbose "[Get-AzDoTeamMember] Member '$MemberName' not found in team '$TeamName'."
        $result.status = [DSCGetSummaryState]::NotFound
    }

    return $result
}
