Function Get-AzDoTeamSettings
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param (
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter(Mandatory = $true)][string]$TeamName,
        [Parameter()][string]$BacklogIterationPath,
        [Parameter()][string]$DefaultIterationPath,
        [Parameter()][string[]]$IterationPaths,
        [Parameter()][string]$DefaultAreaPath,
        [Parameter()][string[]]$AreaPaths,
        [Parameter()][string[]]$WorkingDays,
        [Parameter()][ValidateSet('', 'asRequirements', 'asTasks', 'off')][string]$BugsBehavior,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Get-AzDoTeamSettings] Started for team '$TeamName' in project '$ProjectName'."

    $result = @{
        Ensure            = [Ensure]::Absent
        propertiesChanged = @()
        status            = $null
    }

    # Team settings cannot be removed (they always exist for a team). Treat 'Ensure = Absent' as a
    # no-op that is already in its desired state so the engine does not loop trying to remove it.
    if ($Ensure -eq [Ensure]::Absent)
    {
        Write-Verbose "[Get-AzDoTeamSettings] Ensure = Absent; team settings cannot be removed (no-op)."
        $result.status = [DSCGetSummaryState]::NotFound
        return $result
    }

    $OrgName = Get-AzDoOrganizationName
    $ApiUri  = 'https://dev.azure.com/{0}' -f $OrgName

    # Resolve the project (cache first, then live lookup).
    $project = Get-CacheItem -Key $ProjectName -Type 'LiveProjects'
    if (-not $project)
    {
        $project = Invoke-AzDevOpsApiRestMethod -Uri "$ApiUri/_apis/projects/${ProjectName}?api-version=7.1-preview.4" -Method Get
        if ($project) { Add-CacheItem -Key $ProjectName -Value $project -Type 'LiveProjects' }
    }

    # Resolve the team (cache first, then live lookup).
    $cacheKey = '{0}\{1}' -f $ProjectName, $TeamName
    $team     = Get-CacheItem -Key $cacheKey -Type 'LiveTeams'
    if ((-not $team) -and $project)
    {
        $allTeams = List-DevOpsTeams -ApiUri $ApiUri -ProjectId $project.id
        $team     = $allTeams | Where-Object { $_.name -eq $TeamName } | Select-Object -First 1
        if ($team) { Add-CacheItem -Key $cacheKey -Value $team -Type 'LiveTeams' }
    }

    if ((-not $project) -or (-not $team))
    {
        Write-Verbose "[Get-AzDoTeamSettings] Project or Team not found."
        $result.status = [DSCGetSummaryState]::NotFound
        return $result
    }

    $live = Get-DevOpsTeamSettings -ApiUri $ApiUri -ProjectId $project.id -TeamId $team.id
    $result.liveCache = $live

    # Compare desired properties against the live configuration to detect drift.
    $propertiesChanged = @()

    if ($PSBoundParameters.ContainsKey('BacklogIterationPath') -and $BacklogIterationPath -and
        $live.BacklogIterationPath -ne $BacklogIterationPath) { $propertiesChanged += 'BacklogIterationPath' }

    if ($PSBoundParameters.ContainsKey('DefaultIterationPath') -and $DefaultIterationPath -and
        $live.DefaultIterationPath -ne $DefaultIterationPath) { $propertiesChanged += 'DefaultIterationPath' }

    if ($PSBoundParameters.ContainsKey('DefaultAreaPath') -and $DefaultAreaPath -and
        $live.DefaultAreaPath -ne $DefaultAreaPath) { $propertiesChanged += 'DefaultAreaPath' }

    if ($IterationPaths -and (Test-AzDoArrayDrift -Reference $live.IterationPaths -Difference $IterationPaths)) { $propertiesChanged += 'IterationPaths' }

    if ($AreaPaths -and (Test-AzDoArrayDrift -Reference $live.AreaPaths -Difference $AreaPaths)) { $propertiesChanged += 'AreaPaths' }

    if ($WorkingDays -and (Test-AzDoArrayDrift -Reference $live.WorkingDays -Difference $WorkingDays)) { $propertiesChanged += 'WorkingDays' }

    if ($PSBoundParameters.ContainsKey('BugsBehavior') -and $BugsBehavior -and
        $live.BugsBehavior -ne $BugsBehavior) { $propertiesChanged += 'BugsBehavior' }

    $result.propertiesChanged = $propertiesChanged
    $result.Ensure            = [Ensure]::Present

    if ($propertiesChanged.Count -gt 0)
    {
        Write-Verbose "[Get-AzDoTeamSettings] Drift detected on: $($propertiesChanged -join ', ')."
        $result.status = [DSCGetSummaryState]::Changed
    }
    else
    {
        Write-Verbose "[Get-AzDoTeamSettings] Team settings match desired state."
        $result.status = [DSCGetSummaryState]::Unchanged
    }

    return $result
}
