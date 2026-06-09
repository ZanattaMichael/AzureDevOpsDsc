Function Get-AzDoArtifactFeed
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param (
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter(Mandatory = $true)][string]$FeedName,
        [Parameter()][string]$Description,
        [Parameter()][bool]$BadgesEnabled = $false,
        [Parameter()][bool]$HideDeletedPackageVersions = $true,
        [Parameter()][bool]$UpstreamEnabled = $true,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )
    Write-Verbose "[Get-AzDoArtifactFeed] Started."
    $result = @{ Ensure = [Ensure]::Absent; propertiesChanged = @(); status = $null }
    $feed = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $FeedName) -Type 'LiveArtifactFeeds'
    if ($feed) { $result.liveCache = $feed; $result.status = [DSCGetSummaryState]::Unchanged }
    else        { $result.status = [DSCGetSummaryState]::NotFound }
    return $result
}
