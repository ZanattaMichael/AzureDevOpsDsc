Function Remove-AzDoTeam
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter(Mandatory = $true)][string]$TeamName,
        [Parameter()][string]$Description,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Remove-AzDoTeam] Removing team '$TeamName' from project '$ProjectName'."

    $project = Resolve-AzDoProject -ProjectName $ProjectName
    if (-not $project)
    {
        Write-Error "[Remove-AzDoTeam] Project '$ProjectName' not found."
        return
    }

    $team = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $TeamName) -Type 'LiveTeams'
    if (-not $team)
    {
        # Team may have been created after the cache was built at init — fall back to a live lookup.
        $allTeams = List-DevOpsTeams -ApiUri ('https://dev.azure.com/{0}' -f (Get-AzDoOrganizationName)) -ProjectId $project.id
        $team     = $allTeams | Where-Object { $_.name -eq $TeamName } | Select-Object -First 1
    }

    if (-not $team)
    {
        # Already absent — nothing to remove (desired state achieved).
        Write-Verbose "[Remove-AzDoTeam] Team '$TeamName' not found; already absent."
        return
    }

    $params = @{
        ApiUri    = 'https://dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
        ProjectId = $project.id
        TeamId    = $team.id
    }

    Remove-DevOpsTeam @params

    Remove-CacheItem -Key ('{0}\{1}' -f $ProjectName, $TeamName) -Type 'LiveTeams'
    Export-CacheObject -CacheType 'LiveTeams' -Content $AzDoLiveTeams
    Write-Verbose "[Remove-AzDoTeam] Team '$TeamName' removed successfully."
}
