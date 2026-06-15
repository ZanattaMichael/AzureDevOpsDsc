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
    $project = Resolve-AzDoProject -ProjectName $ProjectName
    if (-not $project) { Write-Error "[New-AzDoWiki] Project not found."; return }

    $repo = if ($RepositoryName) { Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $RepositoryName) -Type 'LiveRepositories' } else { $null }
    if ($RepositoryName -and (-not $repo))
    {
        # Repository may have been created after the cache was built at init — fall back to a live lookup.
        Write-Verbose "[New-AzDoWiki] Repository '$RepositoryName' not in cache — falling back to live API lookup."
        $allRepos = List-DevOpsGitRepository -OrganizationName (Get-AzDoOrganizationName) -ProjectName $ProjectName
        $repo     = $allRepos | Where-Object { $_.name -eq $RepositoryName } | Select-Object -First 1
    }

    $params = @{
        ApiUri       = 'https://dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
        ProjectId    = $project.id
        WikiName     = $WikiName
        WikiType     = $WikiType
        RepositoryId = if ($repo) { $repo.id } else { $null }
        MappedPath   = $MappedPath
    }
    $value = New-DevOpsWiki @params

    if ($null -eq $value)
    {
        Write-Error "[New-AzDoWiki] New-DevOpsWiki returned null. Check authentication token and organization settings."
        return
    }
    Add-CacheItem -Key ('{0}\{1}' -f $ProjectName, $WikiName) -Value $value -Type 'LiveWikis'
    Export-CacheObject -CacheType 'LiveWikis' -Content $AzDoLiveWikis
    Refresh-CacheObject -CacheType 'LiveWikis'
}
