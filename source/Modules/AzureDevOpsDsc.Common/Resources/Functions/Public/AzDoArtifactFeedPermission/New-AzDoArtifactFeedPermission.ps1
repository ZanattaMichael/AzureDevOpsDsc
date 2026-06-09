Function New-AzDoArtifactFeedPermission
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
    Write-Verbose "[New-AzDoArtifactFeedPermission] Started."
    $SecurityNamespace = Get-CacheItem -Key 'Packaging' -Type 'SecurityNamespaces'
    $feedCache         = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $FeedName) -Type 'LiveArtifactFeeds'
    if (-not $SecurityNamespace) { Write-Error "[New-AzDoArtifactFeedPermission] Namespace not found."; return }
    $tokenId = if ($feedCache) { $feedCache.id } else { $FeedName }
    $serializeACLParams = @{
        ReferenceACLs        = $LookupResult.propertiesChanged
        DescriptorACLList    = Get-CacheItem -Key $SecurityNamespace.namespaceId -Type 'LiveACLList'
        DescriptorMatchToken = ($LocalizedDataAzSerializationPatten.GenericPermission -f [regex]::Escape($tokenId))
    }
    $params = @{
        OrganizationName    = (Get-AzDoOrganizationName)
        SecurityNamespaceID = $SecurityNamespace.namespaceId
        SerializedACLs      = ConvertTo-ACLHashtable @serializeACLParams
    }
    Set-AzDoPermission @params
}
