Function Get-AzDoAgentQueue
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param (
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter(Mandatory = $true)][string]$QueueName,
        [Parameter(Mandatory = $true)][string]$PoolName,
        [Parameter()][bool]$AuthorizeAllPipelines = $false,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )
    Write-Verbose "[Get-AzDoAgentQueue] Started."
    $result = @{ Ensure = [Ensure]::Absent; propertiesChanged = @(); status = $null }
    $cacheKey = '{0}\{1}' -f $ProjectName, $QueueName
    $queue = Get-CacheItem -Key $cacheKey -Type 'LiveAgentQueues'
    if (-not $queue)
    {
        Write-Verbose "[Get-AzDoAgentQueue] Queue '$cacheKey' not in cache — falling back to live API lookup."
        $OrgName    = Get-AzDoOrganizationName
        $allQueues  = List-DevOpsAgentQueues -ApiUri "https://dev.azure.com/$OrgName" -ProjectName $ProjectName
        $queue      = $allQueues | Where-Object { $_.name -eq $QueueName } | Select-Object -First 1
        if ($queue) { Add-CacheItem -Key $cacheKey -Value $queue -Type 'LiveAgentQueues' }
    }
    if ($queue) { $result.liveCache = $queue; $result.status = [DSCGetSummaryState]::Unchanged }
    else         { $result.status = [DSCGetSummaryState]::NotFound }
    return $result
}
