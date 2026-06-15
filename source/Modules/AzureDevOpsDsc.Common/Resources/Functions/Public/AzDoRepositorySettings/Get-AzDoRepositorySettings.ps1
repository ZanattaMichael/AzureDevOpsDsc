Function Get-AzDoRepositorySettings
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param (
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter(Mandatory = $true)][string]$RepositoryName,
        [Parameter()][string]$DefaultBranch = 'main',
        [Parameter()][bool]$AllowSquashMerge = $true,
        [Parameter()][bool]$AllowRebaseMerge = $true,
        [Parameter()][bool]$AllowNoFastForward = $true,
        [Parameter()][bool]$DisableForking = $false,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Get-AzDoRepositorySettings] Started."

    $result = @{ Ensure = [Ensure]::Present; propertiesChanged = @(); status = $null }

    $OrgName     = Get-AzDoOrganizationName
    $repoCacheKey = '{0}\{1}' -f $ProjectName, $RepositoryName
    $repository  = Get-CacheItem -Key $repoCacheKey -Type 'LiveRepositories'

    if (-not $repository)
    {
        Write-Verbose "[Get-AzDoRepositorySettings] Repository '$RepositoryName' not in cache — falling back to live API lookup."
        $allRepos   = Invoke-AzDevOpsApiRestMethod -Uri "https://dev.azure.com/$OrgName/$ProjectName/_apis/git/repositories?api-version=7.1-preview.1" -Method Get
        $repository = $allRepos.value | Where-Object { $_.name -eq $RepositoryName } | Select-Object -First 1
        if ($repository) { Add-CacheItem -Key $repoCacheKey -Value $repository -Type 'LiveRepositories' }
    }

    if (-not $repository)
    {
        Write-Warning "[Get-AzDoRepositorySettings] Repository '$RepositoryName' not found."
        $result.status = [DSCGetSummaryState]::NotFound
        return $result
    }

    try
    {
        $params = @{
            ApiUri       = 'https://dev.azure.com/{0}/' -f $OrgName
            ProjectName  = $ProjectName
            RepositoryId = $repository.id
        }
        $settings = Get-DevOpsRepositorySettings @params
        $result.liveCache = $settings

        $changed = @()
        # Only report a field as Changed if the live value is non-null AND differs.
        # The /settings endpoint for many orgs does not return merge-strategy fields;
        # treating null as "no data" avoids an infinite Set→PATCH→404 loop.
        if ($null -ne $settings.allowSquashMerge   -and $settings.allowSquashMerge    -ne $AllowSquashMerge)    { $changed += 'AllowSquashMerge' }
        if ($null -ne $settings.allowNoFastForward -and $settings.allowNoFastForward  -ne $AllowNoFastForward)  { $changed += 'AllowNoFastForward' }
        if ($null -ne $settings.allowRebaseMerge   -and $settings.allowRebaseMerge    -ne $AllowRebaseMerge)    { $changed += 'AllowRebaseMerge' }

        $result.propertiesChanged = $changed
        $result.status = if ($changed.Count -eq 0) { [DSCGetSummaryState]::Unchanged } else { [DSCGetSummaryState]::Changed }
    }
    catch
    {
        # If the settings endpoint is unavailable for this org (e.g. 404), report Unchanged
        # so the resource does not repeatedly try to Set settings it cannot read or write.
        if ($_ -match '404')
        {
            Write-Warning "[Get-AzDoRepositorySettings] Settings endpoint returned 404 — treating as Unchanged."
            $result.status = [DSCGetSummaryState]::Unchanged
        }
        else
        {
            Write-Warning "[Get-AzDoRepositorySettings] Error retrieving settings: $_"
            $result.status = [DSCGetSummaryState]::Error
        }
    }

    return $result
}
