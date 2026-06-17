Function Set-DevOpsAgentQueue
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][string]$ProjectName,
        [Parameter(Mandatory)][int]$QueueId,
        [Parameter()][bool]$AuthorizeAllPipelines = $false,
        [Parameter()][string]$ApiVersion = '7.1'
    )
    $params = @{
        Uri         = '{0}/{1}/_apis/distributedtask/queues/{2}?api-version={3}' -f $ApiUri.TrimEnd('/'), $ProjectName, $QueueId, $ApiVersion
        Method      = 'PATCH'
        ContentType = 'application/json'
        Body        = @{ authorizeAllPipelines = $AuthorizeAllPipelines } | ConvertTo-Json
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[Set-DevOpsAgentQueue] Failed to update queue '$QueueId': $_" }
}
