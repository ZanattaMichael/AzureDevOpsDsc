Function New-AzDoAgentPoolPermission
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
    Write-Verbose "[New-AzDoAgentPoolPermission] Started."
    $OrganizationName  = Get-AzDoOrganizationName
    $SecurityNamespace = Get-CacheItem -Key 'DistributedTask' -Type 'SecurityNamespaces'
    $Pool              = Get-CacheItem -Key $PoolName -Type 'LiveAgentPools'
    if (-not $Pool)
    {
        Write-Verbose "[New-AzDoAgentPoolPermission] Pool '$PoolName' not in cache — falling back to live API lookup."
        $allPools = List-DevOpsAgentPools -ApiUri "https://dev.azure.com/$OrganizationName"
        $Pool     = $allPools | Where-Object { $_.name -eq $PoolName } | Select-Object -First 1
        if ($Pool) { Add-CacheItem -Key $PoolName -Value $Pool -Type 'LiveAgentPools' }
    }
    if (-not $SecurityNamespace) { Write-Error "[New-AzDoAgentPoolPermission] Namespace not found."; return }
    $matchToken = if ($Pool) { $LocalizedDataAzSerializationPatten.AgentPoolPermission -f $Pool.id } else { '.*' }
    $serializeACLParams = @{
        ReferenceACLs        = $LookupResult.propertiesChanged
        DescriptorACLList    = Get-CacheItem -Key $SecurityNamespace.namespaceId -Type 'LiveACLList'
        DescriptorMatchToken = $matchToken
    }
    $params = @{
        OrganizationName    = $OrganizationName
        SecurityNamespaceID = $SecurityNamespace.namespaceId
        SerializedACLs      = ConvertTo-ACLHashtable @serializeACLParams
    }
    Set-AzDoPermission @params
}
