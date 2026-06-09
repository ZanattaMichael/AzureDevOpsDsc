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

    $project = Get-CacheItem -Key $ProjectName -Type 'LiveProjects'
    $team    = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $TeamName) -Type 'LiveTeams'

    if ((-not $project) -or (-not $team))
    {
        Write-Error "[Remove-AzDoTeam] Project or Team not found in cache."
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
