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

    if (-not $feed)
    {
        # Cache miss — query live API so that feeds created outside this session (or before cache
        # population) don't trigger a spurious re-create. Check project scope first, then org scope.
        $apiUri = 'https://feeds.dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
        try
        {
            $feed = List-DevOpsArtifactFeeds -ApiUri $apiUri -ProjectName $ProjectName |
                Where-Object { $_.name -eq $FeedName } |
                Select-Object -First 1
        } catch {
            Write-Verbose "[Get-AzDoArtifactFeed] Project-scope list failed: $_"
        }

        if (-not $feed)
        {
            try
            {
                $feed = List-DevOpsArtifactFeeds -ApiUri $apiUri |
                    Where-Object { $_.name -eq $FeedName } |
                    Select-Object -First 1
            } catch {
                Write-Verbose "[Get-AzDoArtifactFeed] Org-scope list failed: $_"
            }
        }

        if ($feed)
        {
            Add-CacheItem -Key ('{0}\{1}' -f $ProjectName, $FeedName) -Value $feed -Type 'LiveArtifactFeeds'
        }
    }

    if ($feed) { $result.liveCache = $feed; $result.status = [DSCGetSummaryState]::Unchanged }
    else        { $result.status = [DSCGetSummaryState]::NotFound }
    return $result
}
