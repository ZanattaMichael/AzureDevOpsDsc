Function Set-AzDoAgentQueue
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
    Write-Verbose "[Set-AzDoAgentQueue] Updating agent queue '$QueueName'."
    $queue = Get-CacheItem -Key ('{0}\{1}' -f $ProjectName, $QueueName) -Type 'LiveAgentQueues'
    if (-not $queue) { Write-Error "[Set-AzDoAgentQueue] Queue not found."; return }
    $params = @{
        ApiUri               = 'https://dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
        ProjectName          = $ProjectName
        QueueId              = $queue.id
        AuthorizeAllPipelines = $AuthorizeAllPipelines
    }
    $value = Set-DevOpsAgentQueue @params
    Add-CacheItem -Key ('{0}\{1}' -f $ProjectName, $QueueName) -Value $value -Type 'LiveAgentQueues'
    Export-CacheObject -CacheType 'LiveAgentQueues' -Content $AzDoLiveAgentQueues
    Refresh-CacheObject -CacheType 'LiveAgentQueues'
}
