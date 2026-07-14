Function Set-AzDoArtifactFeedPermission
{
    [CmdletBinding()]
    param (
        [Parameter()][string]$ProjectName,
        [Parameter(Mandatory = $true)][string]$FeedName,
        [Parameter()][HashTable[]]$Permissions,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )
    Write-Verbose "[Set-AzDoArtifactFeedPermission] Started."

    $feedCache = if ($LookupResult.feedCache) { $LookupResult.feedCache }
                 else { Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $FeedName) -Type 'LiveArtifactFeeds' }
    if (-not $feedCache) { Write-Error "[Set-AzDoArtifactFeedPermission] Feed '$FeedName' not found."; return }

    $apiUri       = 'https://feeds.dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
    $livePerms    = @(if ($LookupResult.livePermissions) { $LookupResult.livePermissions } else { @() })
    $desiredPerms = @(if ($LookupResult.desiredPermissions) { $LookupResult.desiredPermissions } else { @() })

    # Removals: live perms whose identity is not in the desired set.
    $desiredDescriptors = @($desiredPerms | ForEach-Object { $_.identityDescriptor })
    $removals   = @($livePerms | Where-Object { $_.identityDescriptor -notin $desiredDescriptors } | ForEach-Object {
        [PSCustomObject]@{ role = 'none'; identityDescriptor = $_.identityDescriptor }
    })

    $patchBody = @($removals) + @($desiredPerms)
    if ($patchBody.Count -eq 0) { return }

    Set-DevOpsArtifactFeedPermission -ApiUri $apiUri -ProjectName $ProjectName -FeedId $feedCache.id -Permissions $patchBody
}
