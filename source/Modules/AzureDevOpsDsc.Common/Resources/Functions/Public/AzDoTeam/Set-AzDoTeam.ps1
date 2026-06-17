Function Set-AzDoTeam
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

    Write-Verbose "[Set-AzDoTeam] Updating team '$TeamName' in project '$ProjectName'."

    $project = Get-CacheItem -Key $ProjectName -Type 'LiveProjects'
    $team    = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $TeamName) -Type 'LiveTeams'

    if ((-not $project) -or (-not $team))
    {
        Write-Error "[Set-AzDoTeam] Project or Team not found in cache."
        return
    }

    $params = @{
        ApiUri      = 'https://dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
        ProjectId   = $project.id
        TeamId      = $team.id
        TeamName    = $TeamName
        Description = $Description
    }

    $value = Set-DevOpsTeam @params

    if ($null -eq $value)
    {
        Write-Error "[Set-AzDoTeam] Set-DevOpsTeam returned null. Check authentication token and organization settings."
        return
    }

    Add-CacheItem -Key ('{0}\{1}' -f $ProjectName, $TeamName) -Value $value -Type 'LiveTeams'
    Export-CacheObject -CacheType 'LiveTeams' -Content $AzDoLiveTeams
    Refresh-CacheObject -CacheType 'LiveTeams'
    Write-Verbose "[Set-AzDoTeam] Team '$TeamName' updated successfully."
}
