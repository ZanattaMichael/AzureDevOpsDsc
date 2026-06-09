Function Remove-DevOpsAgentQueue
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][string]$ProjectName,
        [Parameter(Mandatory)][int]$QueueId,
        [Parameter()][string]$ApiVersion = '7.1'
    )
    $params = @{
        Uri    = '{0}/{1}/_apis/distributedtask/queues/{2}?api-version={3}' -f $ApiUri, $ProjectName, $QueueId, $ApiVersion
        Method = 'DELETE'
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[Remove-DevOpsAgentQueue] Failed to remove queue '$QueueId': $_" }
}
