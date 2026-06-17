Function Set-AzDoArtifactFeedSettings
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

    Write-Verbose "[Set-AzDoArtifactFeedSettings] Applying settings for feed '$FeedName' in project '$ProjectName'."

    $feed = Resolve-DevOpsArtifactFeed -ProjectName $ProjectName -FeedName $FeedName
    if (-not $feed)
    {
        Write-Error "[Set-AzDoArtifactFeedSettings] Feed '$FeedName' not found."
        return
    }

    $params = @{
        ApiUri                               = 'https://feeds.dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
        ProjectName                          = $ProjectName
        FeedId                               = $feed.id
        HideDeletedPackageVersions           = $HideDeletedPackageVersions
        RetentionCountLimit                  = $RetentionCountLimit
        DaysToKeepRecentlyDownloadedPackages = $DaysToKeepRecentlyDownloadedPackages
    }
    if ($PSBoundParameters.ContainsKey('UpstreamSources')) { $params.UpstreamSources = $UpstreamSources }

    $value = Set-DevOpsArtifactFeedSettings @params

    if ($null -eq $value)
    {
        Write-Error "[Set-AzDoArtifactFeedSettings] Set-DevOpsArtifactFeedSettings returned null. Check authentication token and organization settings."
        return
    }

    Add-CacheItem -Key ('{0}\{1}' -f $ProjectName, $FeedName) -Value $value -Type 'LiveArtifactFeeds'
    Export-CacheObject -CacheType 'LiveArtifactFeeds' -Content $AzDoLiveArtifactFeeds
    Refresh-CacheObject -CacheType 'LiveArtifactFeeds'
    Write-Verbose "[Set-AzDoArtifactFeedSettings] Feed settings for '$FeedName' applied successfully."
}
