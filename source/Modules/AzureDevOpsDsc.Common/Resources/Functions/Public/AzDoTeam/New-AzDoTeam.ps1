Function New-AzDoTeam
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

    Write-Verbose "[New-AzDoTeam] Creating team '$TeamName' in project '$ProjectName'."

    $project = Get-CacheItem -Key $ProjectName -Type 'LiveProjects'
    if (-not $project)
    {
        Write-Error "[New-AzDoTeam] Project '$ProjectName' not found in cache."
        return
    }

    $params = @{
        ApiUri      = 'https://dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
        ProjectId   = $project.id
        TeamName    = $TeamName
        Description = $Description
    }

    $value = New-DevOpsTeam @params

    Add-CacheItem -Key ('{0}\{1}' -f $ProjectName, $TeamName) -Value $value -Type 'LiveTeams'
    Export-CacheObject -CacheType 'LiveTeams' -Content $AzDoLiveTeams
    Refresh-CacheObject -CacheType 'LiveTeams'
    Write-Verbose "[New-AzDoTeam] Team '$TeamName' created successfully."
}
