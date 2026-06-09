Function Remove-AzDoAgentPoolPermission
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$PoolName,
        [Parameter(Mandatory = $true)][string]$GroupName,
        [Parameter(Mandatory = $true)][bool]$isInherited,
        [Parameter()][HashTable[]]$Permissions,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )
    Write-Verbose "[Remove-AzDoAgentPoolPermission] Started."
    $SecurityNamespace = Get-CacheItem -Key 'AgentPools' -Type 'SecurityNamespaces'
    $Pool              = Get-CacheItem -Key $PoolName -Type 'LiveAgentPools'
    if (-not $SecurityNamespace) { Write-Error "[Remove-AzDoAgentPoolPermission] Namespace not found."; return }
    $tokenString = if ($Pool) { $Pool.id.ToString() } else { $PoolName }
    $params = @{
        OrganizationName    = (Get-AzDoOrganizationName)
        SecurityNamespaceID = $SecurityNamespace.namespaceId
        TokenName           = $tokenString
    }
    Remove-AzDoPermission @params
}
