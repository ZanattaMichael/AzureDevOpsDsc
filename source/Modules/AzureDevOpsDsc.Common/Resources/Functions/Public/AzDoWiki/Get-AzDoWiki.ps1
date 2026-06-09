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
    $wiki = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $WikiName) -Type 'LiveWikis'
    if ($wiki) { $result.liveCache = $wiki; $result.status = [DSCGetSummaryState]::Unchanged }
    else        { $result.status = [DSCGetSummaryState]::NotFound }
    return $result
}
