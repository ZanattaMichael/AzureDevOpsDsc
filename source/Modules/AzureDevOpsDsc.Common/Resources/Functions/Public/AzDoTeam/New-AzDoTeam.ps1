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

    $OrgName = Get-AzDoOrganizationName
    $project = Get-CacheItem -Key $ProjectName -Type 'LiveProjects'
    if (-not $project)
    {
        Write-Verbose "[New-AzDoTeam] Project '$ProjectName' not in cache — falling back to live API lookup."
        $project = Invoke-AzDevOpsApiRestMethod -Uri "https://dev.azure.com/$OrgName/_apis/projects/${ProjectName}?api-version=7.1-preview.4" -Method Get
        if ($project) { Add-CacheItem -Key $ProjectName -Value $project -Type 'LiveProjects' }
    }
    if (-not $project)
    {
        Write-Error "[New-AzDoTeam] Project '$ProjectName' not found."
        return
    }

    $params = @{
        ApiUri      = 'https://dev.azure.com/{0}/' -f $OrgName
        ProjectId   = $project.id
        TeamName    = $TeamName
        Description = $Description
    }

    $value = New-DevOpsTeam @params

    if ($null -eq $value)
    {
        Write-Error "[New-AzDoTeam] New-DevOpsTeam returned null. Check authentication token and organization settings."
        return
    }

    # The projects/teams API does not return a descriptor. Fetch it from the graph descriptors endpoint
    # so that New-AzDoTeamMember can use it to add members via the VSSPS API.
    $descriptor = Get-DevOpsSecurityDescriptor -ProjectId $value.id -Organization $OrgName
    if ($descriptor)
    {
        $value | Add-Member -NotePropertyName 'descriptor' -NotePropertyValue $descriptor -Force
    }

    Add-CacheItem -Key ('{0}\{1}' -f $ProjectName, $TeamName) -Value $value -Type 'LiveTeams'
    Export-CacheObject -CacheType 'LiveTeams' -Content $AzDoLiveTeams
    Refresh-CacheObject -CacheType 'LiveTeams'
    Write-Verbose "[New-AzDoTeam] Team '$TeamName' created successfully."
}
