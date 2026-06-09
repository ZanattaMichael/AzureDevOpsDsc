Function New-AzDoArtifactFeed
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
    Write-Verbose "[New-AzDoArtifactFeed] Creating feed '$FeedName'."
    $params = @{
        ApiUri                     = 'https://feeds.dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
        ProjectName                = $ProjectName
        FeedName                   = $FeedName
        Description                = $Description
        BadgesEnabled              = $BadgesEnabled
        HideDeletedPackageVersions = $HideDeletedPackageVersions
    }
    $value = New-DevOpsArtifactFeed @params

    if ($null -eq $value)
    {
        Write-Error "[New-AzDoArtifactFeed] New-DevOpsArtifactFeed returned null. Check authentication token and organization settings."
        return
    }
    Add-CacheItem -Key ('{0}\{1}' -f $ProjectName, $FeedName) -Value $value -Type 'LiveArtifactFeeds'
    Export-CacheObject -CacheType 'LiveArtifactFeeds' -Content $AzDoLiveArtifactFeeds
    Refresh-CacheObject -CacheType 'LiveArtifactFeeds'
}
