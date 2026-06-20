Function Set-AzDoTeamSettings
{
    [CmdletBinding()]
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

    Write-Verbose "[Set-AzDoTeamSettings] Applying settings for team '$TeamName' in project '$ProjectName'."

    $OrgName = Get-AzDoOrganizationName
    $ApiUri  = 'https://dev.azure.com/{0}' -f $OrgName

    $project = Resolve-AzDoProject -ProjectName $ProjectName
    if (-not $project)
    {
        Write-Error "[Set-AzDoTeamSettings] Project '$ProjectName' not found."
        return
    }

    $team = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $TeamName) -Type 'LiveTeams'
    if (-not $team)
    {
        $allTeams = List-DevOpsTeams -ApiUri $ApiUri -ProjectId $project.id
        $team     = $allTeams | Where-Object { $_.name -eq $TeamName } | Select-Object -First 1
    }
    if (-not $team)
    {
        Write-Error "[Set-AzDoTeamSettings] Team '$TeamName' not found in project '$ProjectName'."
        return
    }

    $params = @{ ApiUri = $ApiUri; ProjectId = $project.id; TeamId = $team.id }
    foreach ($name in 'BacklogIterationPath', 'DefaultIterationPath', 'IterationPaths', 'DefaultAreaPath', 'AreaPaths', 'WorkingDays', 'BugsBehavior')
    {
        if ($PSBoundParameters.ContainsKey($name)) { $params[$name] = $PSBoundParameters[$name] }
    }

    $value = Set-DevOpsTeamSettings @params

    if ($null -eq $value)
    {
        Write-Error "[Set-AzDoTeamSettings] Set-DevOpsTeamSettings returned null. Check authentication token and organization settings."
        return
    }

    Write-Verbose "[Set-AzDoTeamSettings] Team settings for '$TeamName' applied successfully."
}
