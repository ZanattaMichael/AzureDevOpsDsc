Function Remove-DevOpsAgentPool
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][int]$PoolId,
        [Parameter()][string]$ApiVersion = '7.1'
    )
    $params = @{
        Uri    = '{0}/_apis/distributedtask/pools/{1}?api-version={2}' -f $ApiUri.TrimEnd('/'), $PoolId, $ApiVersion
        Method = 'DELETE'
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[Remove-DevOpsAgentPool] Failed to remove pool '$PoolId': $_" }
}
