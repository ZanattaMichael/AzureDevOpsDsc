Function New-DevOpsAgentQueue
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][string]$ProjectName,
        [Parameter(Mandatory)][string]$QueueName,
        [Parameter(Mandatory)][int]$PoolId,
        [Parameter()][bool]$AuthorizeAllPipelines = $false,
        [Parameter()][string]$ApiVersion = '7.1'
    )
    $params = @{
        Uri         = '{0}/{1}/_apis/distributedtask/queues?api-version={2}' -f $ApiUri, $ProjectName, $ApiVersion
        Method      = 'POST'
        ContentType = 'application/json'
        Body        = @{
            name                 = $QueueName
            pool                 = @{ id = $PoolId }
            authorizeAllPipelines = $AuthorizeAllPipelines
        } | ConvertTo-Json
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[New-DevOpsAgentQueue] Failed to create queue '$QueueName': $_" }
}
