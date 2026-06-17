Function Get-AzDoWiki
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
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
    Write-Verbose "[Get-AzDoWiki] Started."
    $result = @{ Ensure = [Ensure]::Absent; propertiesChanged = @(); status = $null }
    $cacheKey = '{0}\{1}' -f $ProjectName, $WikiName
    $wiki = Get-CacheItem -Key $cacheKey -Type 'LiveWikis'

    if (-not $wiki)
    {
        Write-Verbose "[Get-AzDoWiki] Wiki '$WikiName' not in cache — falling back to live API lookup."
        $OrgName   = Get-AzDoOrganizationName
        $allWikis  = List-DevOpsWikis -ApiUri "https://dev.azure.com/$OrgName" -ProjectName $ProjectName
        $wiki      = $allWikis | Where-Object { $_.name -eq $WikiName } | Select-Object -First 1
        if ($wiki) { Add-CacheItem -Key $cacheKey -Value $wiki -Type 'LiveWikis' }
    }

    if ($wiki) { $result.liveCache = $wiki; $result.status = [DSCGetSummaryState]::Unchanged }
    else        { $result.status = [DSCGetSummaryState]::NotFound }
    return $result
}
