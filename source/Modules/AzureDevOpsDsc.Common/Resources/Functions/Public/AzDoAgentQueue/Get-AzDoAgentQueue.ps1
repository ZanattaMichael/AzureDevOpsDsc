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
    $queue = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $QueueName) -Type 'LiveAgentQueues'
    if ($queue) { $result.liveCache = $queue; $result.status = [DSCGetSummaryState]::Unchanged }
    else         { $result.status = [DSCGetSummaryState]::NotFound }
    return $result
}
