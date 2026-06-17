Function Remove-AzDoArtifactFeedSettings
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter(Mandatory = $true)][string]$FeedName,
        [Parameter()][object[]]$UpstreamSources,
        [Parameter()][bool]$HideDeletedPackageVersions = $true,
        [Parameter()][int]$RetentionCountLimit = 0,
        [Parameter()][int]$DaysToKeepRecentlyDownloadedPackages = 0,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )

    # Feed settings are intrinsic to the feed and cannot be deleted independently of it.
    # 'Ensure = Absent' is therefore a no-op for this resource; remove the feed itself with AzDoArtifactFeed.
    Write-Verbose "[Remove-AzDoArtifactFeedSettings] Feed settings for '$FeedName' cannot be removed; manage the feed via AzDoArtifactFeed instead."
}
