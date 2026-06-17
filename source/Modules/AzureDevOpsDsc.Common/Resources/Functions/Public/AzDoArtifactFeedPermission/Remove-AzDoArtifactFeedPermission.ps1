Function Remove-AzDoArtifactFeedPermission
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter(Mandatory = $true)][string]$FeedName,
        [Parameter()][HashTable[]]$Permissions,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )
    Write-Verbose "[Remove-AzDoArtifactFeedPermission] Started."

    $feedCache = if ($LookupResult -and $LookupResult.feedCache) { $LookupResult.feedCache }
                 else { Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $FeedName) -Type 'LiveArtifactFeeds' }
    if (-not $feedCache) { Write-Verbose "[Remove-AzDoArtifactFeedPermission] Feed '$FeedName' not found; nothing to remove."; return }

    $apiUri    = 'https://feeds.dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
    $livePerms = @(if ($LookupResult -and $LookupResult.livePermissions) { $LookupResult.livePermissions } else {
        Get-DevOpsArtifactFeedPermission -ApiUri $apiUri -ProjectName $ProjectName -FeedId $feedCache.id |
            Where-Object { -not $_.isInheritedRole }
    })

    if ($livePerms.Count -eq 0) { return }

    $removals = @($livePerms | ForEach-Object {
        [PSCustomObject]@{ role = 'none'; identityDescriptor = $_.identityDescriptor }
    })

    Set-DevOpsArtifactFeedPermission -ApiUri $apiUri -ProjectName $ProjectName -FeedId $feedCache.id -Permissions $removals
}
