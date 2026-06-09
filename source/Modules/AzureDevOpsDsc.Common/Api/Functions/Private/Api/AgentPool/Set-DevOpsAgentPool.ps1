Function Set-DevOpsAgentPool
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][int]$PoolId,
        [Parameter()][string]$PoolName,
        [Parameter()][bool]$AutoUpdate,
        [Parameter()][bool]$AutoProvision,
        [Parameter()][string]$ApiVersion = '7.1'
    )
    $body = @{ name = $PoolName; autoUpdate = $AutoUpdate; autoProvision = $AutoProvision }
    $params = @{
        Uri         = '{0}/_apis/distributedtask/pools/{1}?api-version={2}' -f $ApiUri, $PoolId, $ApiVersion
        Method      = 'PATCH'
        ContentType = 'application/json'
        Body        = $body | ConvertTo-Json
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[Set-DevOpsAgentPool] Failed to update pool '$PoolId': $_" }
}
