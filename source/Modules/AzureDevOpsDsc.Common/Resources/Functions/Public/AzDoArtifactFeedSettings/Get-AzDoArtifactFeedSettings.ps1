Function Get-AzDoArtifactFeedSettings
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param (
        [Parameter()][string]$ProjectName,
        [Parameter(Mandatory = $true)][string]$FeedName,
        [Parameter()][object[]]$UpstreamSources,
        [Parameter()][bool]$HideDeletedPackageVersions = $true,
        [Parameter()][int]$RetentionCountLimit = 0,
        [Parameter()][int]$DaysToKeepRecentlyDownloadedPackages = 0,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Get-AzDoArtifactFeedSettings] Started for feed '$FeedName' in project '$ProjectName'."

    $result = @{ Ensure = [Ensure]::Absent; propertiesChanged = @(); status = $null }

    # Feed settings cannot be removed independently of the feed. Treat 'Ensure = Absent' as a no-op
    # that is already in its desired state so the engine does not loop trying to remove it.
    if ($Ensure -eq [Ensure]::Absent)
    {
        Write-Verbose "[Get-AzDoArtifactFeedSettings] Ensure = Absent; feed settings cannot be removed (no-op)."
        $result.status = [DSCGetSummaryState]::NotFound
        return $result
    }

    $feed = Resolve-DevOpsArtifactFeed -ProjectName $ProjectName -FeedName $FeedName
    if (-not $feed)
    {
        Write-Verbose "[Get-AzDoArtifactFeedSettings] Feed '$FeedName' not found."
        $result.status = [DSCGetSummaryState]::NotFound
        return $result
    }

    $result.liveCache = $feed
    $result.Ensure    = [Ensure]::Present

    # Compare desired settings against the live feed to detect drift.
    $propertiesChanged = @()

    if ($PSBoundParameters.ContainsKey('HideDeletedPackageVersions') -and
        [bool]$feed.hideDeletedPackageVersions -ne $HideDeletedPackageVersions) { $propertiesChanged += 'HideDeletedPackageVersions' }

    if ($UpstreamSources)
    {
        $liveNames    = @($feed.upstreamSources | ForEach-Object { $_.name })
        $desiredNames = @($UpstreamSources       | ForEach-Object { if ($_ -is [string]) { $_ } else { $_.name } })
        if (Test-AzDoArrayDrift -Reference $liveNames -Difference $desiredNames) { $propertiesChanged += 'UpstreamSources' }
    }

    # Retention policy is only managed when a positive count limit is requested.
    if ($RetentionCountLimit -gt 0)
    {
        $apiUri    = 'https://feeds.dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
        $retention = Get-DevOpsArtifactFeedRetentionPolicy -ApiUri $apiUri -ProjectName $ProjectName -FeedId $feed.id

        if ((-not $retention) -or ([int]$retention.countLimit -ne $RetentionCountLimit))
        {
            $propertiesChanged += 'RetentionCountLimit'
        }
        if ((-not $retention) -or ([int]$retention.daysToKeepRecentlyDownloadedPackages -ne $DaysToKeepRecentlyDownloadedPackages))
        {
            $propertiesChanged += 'DaysToKeepRecentlyDownloadedPackages'
        }
    }

    $result.propertiesChanged = $propertiesChanged

    if ($propertiesChanged.Count -gt 0)
    {
        Write-Verbose "[Get-AzDoArtifactFeedSettings] Drift detected on: $($propertiesChanged -join ', ')."
        $result.status = [DSCGetSummaryState]::Changed
    }
    else
    {
        Write-Verbose "[Get-AzDoArtifactFeedSettings] Feed settings match desired state."
        $result.status = [DSCGetSummaryState]::Unchanged
    }

    return $result
}
