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
    $SecurityNamespace = Get-CacheItem -Key 'Packaging' -Type 'SecurityNamespaces'
    $feedCache         = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $FeedName) -Type 'LiveArtifactFeeds'
    if (-not $SecurityNamespace) { Write-Error "[Remove-AzDoArtifactFeedPermission] Namespace not found."; return }
    $tokenId = if ($feedCache) { $feedCache.id } else { $FeedName }
    $params = @{
        OrganizationName    = (Get-AzDoOrganizationName)
        SecurityNamespaceID = $SecurityNamespace.namespaceId
        TokenName           = $tokenId
    }
    Remove-AzDoPermission @params
}
