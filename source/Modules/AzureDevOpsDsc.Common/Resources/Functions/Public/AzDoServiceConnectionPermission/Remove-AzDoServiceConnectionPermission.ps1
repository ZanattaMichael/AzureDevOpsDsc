Function Remove-AzDoServiceConnectionPermission
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter(Mandatory = $true)][string]$ConnectionName,
        [Parameter(Mandatory = $true)][string]$GroupName,
        [Parameter(Mandatory = $true)][bool]$isInherited,
        [Parameter()][HashTable[]]$Permissions,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )
    Write-Verbose "[Remove-AzDoServiceConnectionPermission] Started."
    $SecurityNamespace = Get-CacheItem -Key 'ServiceEndpoints' -Type 'SecurityNamespaces'
    $Project           = Get-CacheItem -Key $ProjectName -Type 'LiveProjects'
    $SC                = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $ConnectionName) -Type 'LiveServiceConnections'
    if ((-not $SecurityNamespace) -or (-not $Project)) { Write-Error "[Remove-AzDoServiceConnectionPermission] Cache miss."; return }
    $tokenString = if ($SC) {
        'endpoints/Project/{0}/endpoint/{1}' -f $Project.id, $SC.id
    } else {
        'endpoints/Project/{0}' -f $Project.id
    }
    $params = @{
        OrganizationName    = (Get-AzDoOrganizationName)
        SecurityNamespaceID = $SecurityNamespace.namespaceId
        TokenName           = $tokenString
    }
    Remove-AzDoPermission @params
}
