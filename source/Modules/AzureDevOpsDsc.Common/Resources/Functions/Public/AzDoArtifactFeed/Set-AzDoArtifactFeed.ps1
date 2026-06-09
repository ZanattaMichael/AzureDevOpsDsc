Function Set-AzDoArtifactFeed
{
    [CmdletBinding()]
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
    Write-Verbose "[Set-AzDoArtifactFeed] Updating feed '$FeedName'."
    $feed = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $FeedName) -Type 'LiveArtifactFeeds'
    if (-not $feed) { Write-Error "[Set-AzDoArtifactFeed] Feed not found."; return }
    $params = @{
        ApiUri                     = 'https://feeds.dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
        ProjectName                = $ProjectName
        FeedId                     = $feed.id
        FeedName                   = $FeedName
        Description                = $Description
        BadgesEnabled              = $BadgesEnabled
        HideDeletedPackageVersions = $HideDeletedPackageVersions
    }
    $value = Set-DevOpsArtifactFeed @params
    Add-CacheItem -Key ('{0}\{1}' -f $ProjectName, $FeedName) -Value $value -Type 'LiveArtifactFeeds'
    Export-CacheObject -CacheType 'LiveArtifactFeeds' -Content $AzDoLiveArtifactFeeds
    Refresh-CacheObject -CacheType 'LiveArtifactFeeds'
}
