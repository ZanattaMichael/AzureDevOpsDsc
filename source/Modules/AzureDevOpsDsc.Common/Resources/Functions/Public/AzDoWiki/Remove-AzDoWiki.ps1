Function Remove-AzDoWiki
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
    Write-Verbose "[Remove-AzDoWiki] Removing wiki '$WikiName'."
    $wiki = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $WikiName) -Type 'LiveWikis'
    if (-not $wiki) { Write-Error "[Remove-AzDoWiki] Wiki not found."; return }
    $params = @{
        ApiUri = 'https://dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
        WikiId = $wiki.id
    }
    Remove-DevOpsWiki @params
    Remove-CacheItem -Key ('{0}\{1}' -f $ProjectName, $WikiName) -Type 'LiveWikis'
    Export-CacheObject -CacheType 'LiveWikis' -Content $AzDoLiveWikis
}
