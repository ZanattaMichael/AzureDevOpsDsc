Function New-AzDoWiki
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter(Mandatory = $true)][string]$WikiName,
        [Parameter()][string]$WikiType = 'projectWiki',
        [Parameter()][string]$RepositoryName,
        [Parameter()][string]$MappedPath = '/',
        [Parameter()][string]$Version,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )
    Write-Verbose "[New-AzDoWiki] Creating wiki '$WikiName'."
    $project = Get-CacheItem -Key $ProjectName -Type 'LiveProjects'
    if (-not $project) { Write-Error "[New-AzDoWiki] Project not found."; return }

    $repo = if ($RepositoryName) { Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $RepositoryName) -Type 'LiveRepositories' } else { $null }

    $params = @{
        ApiUri       = 'https://dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
        ProjectId    = $project.id
        WikiName     = $WikiName
        WikiType     = $WikiType
        RepositoryId = if ($repo) { $repo.id } else { $null }
        MappedPath   = $MappedPath
    }
    $value = New-DevOpsWiki @params
    Add-CacheItem -Key ('{0}\{1}' -f $ProjectName, $WikiName) -Value $value -Type 'LiveWikis'
    Export-CacheObject -CacheType 'LiveWikis' -Content $AzDoLiveWikis
    Refresh-CacheObject -CacheType 'LiveWikis'
}
