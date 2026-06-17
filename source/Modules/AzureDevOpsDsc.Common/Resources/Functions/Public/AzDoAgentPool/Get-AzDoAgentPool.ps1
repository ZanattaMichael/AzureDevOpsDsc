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
    if ($pool) { $result.liveCache = $pool; $result.status = [DSCGetSummaryState]::Unchanged }
    else        { $result.status = [DSCGetSummaryState]::NotFound }
    return $result
}
