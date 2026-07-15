Function Resolve-DevOpsArtifactFeed
{
    <#
        .SYNOPSIS
            Resolves an Azure Artifacts feed by name, checking the cache first and then the live API.
        .DESCRIPTION
            Returns the feed object for the given project/feed name combination, or $null if it cannot
            be found. Checks the 'LiveArtifactFeeds' cache first, then falls back to a project-scope and
            finally an organization-scope live lookup (mirroring Get-AzDoArtifactFeed).
    #>
    [CmdletBinding()]
    param(
        [Parameter()][string]$ProjectName,
        [Parameter(Mandatory)][string]$FeedName
    )

    $cacheKey = '{0}\{1}' -f $ProjectName, $FeedName
    $feed     = Get-CacheItem -Key $cacheKey -Type 'LiveArtifactFeeds'
    if ($feed) { return $feed }

    $apiUri = 'https://feeds.dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)

    try
    {
        $feed = List-DevOpsArtifactFeeds -ApiUri $apiUri -ProjectName $ProjectName |
            Where-Object { $_.name -eq $FeedName } | Select-Object -First 1
    }
    catch { Write-Verbose "[Resolve-DevOpsArtifactFeed] Project-scope list failed: $_" }

    if (-not $feed)
    {
        try
        {
            $feed = List-DevOpsArtifactFeeds -ApiUri $apiUri |
                Where-Object { $_.name -eq $FeedName } | Select-Object -First 1
        }
        catch { Write-Verbose "[Resolve-DevOpsArtifactFeed] Org-scope list failed: $_" }
    }

    if ($feed) { Add-CacheItem -Key $cacheKey -Value $feed -Type 'LiveArtifactFeeds' }
    return $feed
}
