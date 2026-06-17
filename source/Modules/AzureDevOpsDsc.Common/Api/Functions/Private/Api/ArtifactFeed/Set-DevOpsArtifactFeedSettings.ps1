Function Set-DevOpsArtifactFeedSettings
{
    <#
        .SYNOPSIS
            Applies the configurable settings of an Azure Artifacts feed.
        .DESCRIPTION
            Updates the upstream sources and hide-deleted-package-versions behaviour via a PATCH to the
            feed, and the artifact lifecycle (retention policy) via a PUT to the feed's retention
            policies endpoint. The retention policy is only applied when 'RetentionCountLimit' is
            greater than zero.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter()][string]$ProjectName,
        [Parameter(Mandatory)][string]$FeedId,
        [Parameter()][object[]]$UpstreamSources,
        [Parameter()][bool]$HideDeletedPackageVersions = $true,
        [Parameter()][int]$RetentionCountLimit = 0,
        [Parameter()][int]$DaysToKeepRecentlyDownloadedPackages = 0,
        [Parameter()][string]$ApiVersion = '7.1-preview.1'
    )

    $baseUri = if ($ProjectName) { '{0}/{1}' -f $ApiUri.TrimEnd('/'), $ProjectName } else { $ApiUri.TrimEnd('/') }

    # --- Feed-level settings (PATCH) -----------------------------------------------------
    $body = @{ hideDeletedPackageVersions = $HideDeletedPackageVersions }
    if ($UpstreamSources) { $body.upstreamSources = @($UpstreamSources) }

    try
    {
        $feed = Invoke-AzDevOpsApiRestMethod `
            -Uri ('{0}/_apis/packaging/feeds/{1}?api-version={2}' -f $baseUri, $FeedId, $ApiVersion) `
            -Method Patch -ContentType 'application/json' -Body ($body | ConvertTo-Json -Depth 10)
    }
    catch { Throw "[Set-DevOpsArtifactFeedSettings] Failed to update settings for feed '$FeedId': $_" }

    # --- Artifact lifecycle / retention policy (PUT) -------------------------------------
    # A RetentionCountLimit of 0 means retention is not managed by this resource.
    if ($RetentionCountLimit -gt 0)
    {
        $retentionBody = @{
            countLimit                           = $RetentionCountLimit
            daysToKeepRecentlyDownloadedPackages = $DaysToKeepRecentlyDownloadedPackages
        }
        try
        {
            Invoke-AzDevOpsApiRestMethod `
                -Uri ('{0}/_apis/packaging/feeds/{1}/retentionpolicies?api-version={2}' -f $baseUri, $FeedId, $ApiVersion) `
                -Method Put -ContentType 'application/json' -Body ($retentionBody | ConvertTo-Json) | Out-Null
        }
        catch { Throw "[Set-DevOpsArtifactFeedSettings] Failed to update retention policy for feed '$FeedId': $_" }
    }

    return $feed
}
