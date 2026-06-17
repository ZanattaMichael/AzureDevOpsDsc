Function Get-AzDoAgentPoolPermission
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param (
        [Parameter(Mandatory = $true)][string]$PoolName,
        [Parameter(Mandatory = $true)][string]$GroupName,
        [Parameter(Mandatory = $true)][bool]$isInherited,
        [Parameter()][HashTable[]]$Permissions,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Get-AzDoAgentPoolPermission] Started."

    $SecurityNamespace = 'DistributedTask'
    $OrganizationName  = (Get-AzDoOrganizationName)

    $getResult = @{ Ensure = [Ensure]::Absent; propertiesChanged = @(); status = $null; reason = $null }

    $poolCache = Get-CacheItem -Key $PoolName -Type 'LiveAgentPools'
    if (-not $poolCache)
    {
        Write-Verbose "[Get-AzDoAgentPoolPermission] Pool '$PoolName' not in cache — falling back to live API lookup."
        $allPools  = List-DevOpsAgentPools -ApiUri "https://dev.azure.com/$OrganizationName"
        $poolCache = $allPools | Where-Object { $_.name -eq $PoolName } | Select-Object -First 1
        if ($poolCache) { Add-CacheItem -Key $PoolName -Value $poolCache -Type 'LiveAgentPools' }
    }

    $namespace = Get-CacheItem -Key $SecurityNamespace -Type 'SecurityNamespaces'
    if (-not $namespace) { Write-Error "[Get-AzDoAgentPoolPermission] Security namespace not found."; $getResult.status = [DSCGetSummaryState]::Error; return $getResult }

    $getResult.namespace = $namespace

    # Token-scope the ACL fetch to just this pool's ACL (token = pool id) instead of pulling every
    # ACL in the namespace. Fall back to the full-namespace fetch if the token-scoped query returns
    # nothing, so behaviour is never worse than the previous full scan.
    $aclToken   = if ($poolCache) { $poolCache.id.ToString() } else { $null }
    $DevOpsACLs = if ($aclToken) { Get-DevOpsACL -OrganizationName $OrganizationName -SecurityDescriptorId $namespace.namespaceId -Token $aclToken } else { $null }
    if (-not $DevOpsACLs) { $DevOpsACLs = Get-DevOpsACL -OrganizationName $OrganizationName -SecurityDescriptorId $namespace.namespaceId }
    $DifferenceACLs = $DevOpsACLs | ConvertTo-FormattedACL -SecurityNamespace $SecurityNamespace -OrganizationName $OrganizationName

    if ($poolCache)
    {
        $DifferenceACLs = $DifferenceACLs | Where-Object {
            ($_.Token.Type -eq 'AgentPool') -and ($_.Token.PoolId -eq $poolCache.id.ToString())
        }
    }

    $params = @{
        Permissions       = $Permissions
        SecurityNamespace = $SecurityNamespace
        isInherited       = $isInherited
        OrganizationName  = $OrganizationName
        TokenName         = $PoolName
    }

    $ReferenceACLs = ConvertTo-ACL @params

    $compareResult = Test-ACLListforChanges -ReferenceACLs $ReferenceACLs -DifferenceACLs $DifferenceACLs
    $getResult.propertiesChanged = $compareResult.propertiesChanged
    $getResult.status = [DSCGetSummaryState]::"$($compareResult.status)"
    $getResult.reason = $compareResult.reason
    $getResult.ReferenceACLs  = $ReferenceACLs
    $getResult.DifferenceACLs = $DifferenceACLs

    return $getResult
}
