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
    if (-not $namespace) { Write-Error "[Get-AzDoAgentPoolPermission] Security namespace not found." -ErrorAction Continue; $getResult.status = [DSCGetSummaryState]::Error; return $getResult }

    $getResult.namespace = $namespace

    # Token-scope the ACL fetch to just this pool's ACL (token = pool id) instead of pulling every
    # ACL in the namespace. Fall back to the full-namespace fetch if the token-scoped query returns
    # nothing, so behaviour is never worse than the previous full scan.
    $aclToken   = if ($poolCache) { $poolCache.id.ToString() } else { $null }
    $DevOpsACLs = if ($aclToken) { Get-DevOpsACL -OrganizationName $OrganizationName -SecurityDescriptorId $namespace.namespaceId -Token $aclToken } else { $null }
    if (-not $DevOpsACLs) { $DevOpsACLs = Get-DevOpsACL -OrganizationName $OrganizationName -SecurityDescriptorId $namespace.namespaceId }

    # Drop the ACLs this lookup cannot be interested in BEFORE formatting them, exactly as
    # Get-AzDoProjectPermission and Get-AzDoProcessPermission already do. Formatting resolves every
    # ACE through Find-Identity, which costs an API round trip for each descriptor that is not
    # already cached, so formatting a whole namespace only to keep one token is where the time goes.
    # The fallback above fires whenever the agent pool has no explicit ACL - the normal state
    # once permissions revert to inherited - so the full namespace is the common path, not a rare
    # one. The AgentPool pattern is anchored, so the parsed filter below can only keep
    # a token equal to $aclToken: this drops exactly what that filter would have dropped. Only
    # applied when the pool resolved, because the filter below is skipped in that case too.
    if ($aclToken) { $DevOpsACLs = @($DevOpsACLs | Where-Object { $_.token -eq $aclToken }) }

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
