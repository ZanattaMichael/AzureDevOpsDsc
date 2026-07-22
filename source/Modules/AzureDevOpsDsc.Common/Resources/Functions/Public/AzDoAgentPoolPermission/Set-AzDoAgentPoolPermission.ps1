Function Set-AzDoAgentPoolPermission
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
    Write-Verbose "[Set-AzDoAgentPoolPermission] Started."
    $OrganizationName  = Get-AzDoOrganizationName
    $SecurityNamespace = Get-CacheItem -Key 'DistributedTask' -Type 'SecurityNamespaces'
    $Pool              = Get-CacheItem -Key $PoolName -Type 'LiveAgentPools'
    if (-not $Pool)
    {
        Write-Verbose "[Set-AzDoAgentPoolPermission] Pool '$PoolName' not in cache — falling back to live API lookup."
        $allPools = List-DevOpsAgentPools -ApiUri "https://dev.azure.com/$OrganizationName"
        $Pool     = $allPools | Where-Object { $_.name -eq $PoolName } | Select-Object -First 1
        if ($Pool) { Add-CacheItem -Key $PoolName -Value $Pool -Type 'LiveAgentPools' }
    }
    if (-not $SecurityNamespace) { Write-Error "[Set-AzDoAgentPoolPermission] Namespace not found."; return }
    $matchToken = if ($Pool) { $LocalizedDataAzSerializationPatten.AgentPoolPermission -f $Pool.id } else { '.*' }
    # DescriptorACLList intentionally empty: 'merge=false' on the Set-AzDoPermission POST replaces the
    # ACL per-token (only tokens present in the request body are touched), so there is no need to
    # re-submit every other token's ACL. Merging in the whole namespace-wide 'LiveACLList' cache (as
    # this used to) meant the request body grew with every OTHER pool's cached ACL across the org -
    # same bug/fix as Set-AzDoSecurityNamespacePermission.ps1.
    $serializeACLParams = @{
        ReferenceACLs        = $LookupResult.propertiesChanged
        DescriptorACLList    = @()
        DescriptorMatchToken = $matchToken
    }
    $params = @{
        OrganizationName    = $OrganizationName
        SecurityNamespaceID = $SecurityNamespace.namespaceId
        SerializedACLs      = ConvertTo-ACLHashtable @serializeACLParams
        ClearACEs           = $true
        DifferenceACLs      = $LookupResult.DifferenceACLs
    }
    Set-AzDoPermission @params
}
