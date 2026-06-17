Function Remove-AzDoAgentQueue
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$ProjectName,
        [Parameter(Mandatory = $true)][string]$QueueName,
        [Parameter(Mandatory = $true)][string]$PoolName,
        [Parameter()][bool]$AuthorizeAllPipelines = $false,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )
    Write-Verbose "[Remove-AzDoAgentQueue] Removing agent queue '$QueueName'."
    $queue = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $QueueName) -Type 'LiveAgentQueues'
    if (-not $queue) { Write-Error "[Remove-AzDoAgentQueue] Queue not found."; return }
    $params = @{
        ApiUri      = 'https://dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
        ProjectName = $ProjectName
        QueueId     = $queue.id
    }
    Remove-DevOpsAgentQueue @params
    Remove-CacheItem -Key ('{0}\{1}' -f $ProjectName, $QueueName) -Type 'LiveAgentQueues'
    Export-CacheObject -CacheType 'LiveAgentQueues' -Content $AzDoLiveAgentQueues
}
