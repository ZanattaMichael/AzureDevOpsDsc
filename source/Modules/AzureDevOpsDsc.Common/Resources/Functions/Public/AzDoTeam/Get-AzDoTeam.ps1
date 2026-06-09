Function Get-AzDoTeam
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param (
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter(Mandatory = $true)][string]$TeamName,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Get-AzDoTeam] Started."

    $result = @{
        Ensure            = [Ensure]::Absent
        propertiesChanged = @()
        status            = $null
    }

    $team = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $TeamName) -Type 'LiveTeams'

    if ($team)
    {
        Write-Verbose "[Get-AzDoTeam] Team '$TeamName' found in cache."
        $result.liveCache = $team
        $result.status    = [DSCGetSummaryState]::Unchanged
    }
    else
    {
        Write-Verbose "[Get-AzDoTeam] Team '$TeamName' not found."
        $result.status = [DSCGetSummaryState]::NotFound
    }

    return $result
}
