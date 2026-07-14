Function Get-AzDoAgentPool
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param (
        [Parameter(Mandatory = $true)][string]$PoolName,
        [Parameter()][string]$PoolType = 'automation',
        [Parameter()][bool]$AutoProvision = $false,
        [Parameter()][bool]$AutoUpdate = $true,
        [Parameter()][bool]$IsHosted = $false,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )
    Write-Verbose "[Get-AzDoAgentPool] Started."
    $result = @{ Ensure = [Ensure]::Absent; propertiesChanged = @(); status = $null }
    $pool = Get-CacheItem -Key $PoolName -Type 'LiveAgentPools'
    if (-not $pool)
    {
        Write-Verbose "[Get-AzDoAgentPool] Pool '$PoolName' not in cache — falling back to live API lookup."
        $OrgName  = Get-AzDoOrganizationName
        $allPools = List-DevOpsAgentPools -ApiUri "https://dev.azure.com/$OrgName"
        $pool     = $allPools | Where-Object { $_.name -eq $PoolName } | Select-Object -First 1
        if ($pool) { Add-CacheItem -Key $PoolName -Value $pool -Type 'LiveAgentPools' }
    }
    if ($pool) { $result.liveCache = $pool; $result.status = [DSCGetSummaryState]::Unchanged }
    else        { $result.status = [DSCGetSummaryState]::NotFound }
    return $result
}
