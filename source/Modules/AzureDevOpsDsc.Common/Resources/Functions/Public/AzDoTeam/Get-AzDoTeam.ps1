Function Get-AzDoTeam
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param (
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter(Mandatory = $true)][string]$TeamName,
        [Parameter()][string]$Description,
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

    $cacheKey = '{0}\{1}' -f $ProjectName, $TeamName
    $team = Get-CacheItem -Key $cacheKey -Type 'LiveTeams'

    if (-not $team)
    {
        Write-Verbose "[Get-AzDoTeam] Team '$TeamName' not in cache — falling back to live API lookup."
        $OrgName = Get-AzDoOrganizationName
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
            if ($team) { Add-CacheItem -Key $cacheKey -Value $team -Type 'LiveTeams' }
        }
    }

    if ($team)
    {
        Write-Verbose "[Get-AzDoTeam] Team '$TeamName' found."
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
