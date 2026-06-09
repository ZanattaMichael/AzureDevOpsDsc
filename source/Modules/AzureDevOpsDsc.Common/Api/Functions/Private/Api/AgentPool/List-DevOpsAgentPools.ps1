Function List-DevOpsAgentPools
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter()][string]$ApiVersion = '7.1'
    )
    $params = @{
        Uri    = '{0}/_apis/distributedtask/pools?api-version={1}' -f $ApiUri, $ApiVersion
        Method = 'GET'
    }
    try   { return (Invoke-AzDevOpsApiRestMethod @params).value }
    catch { Throw "[List-DevOpsAgentPools] Failed to list agent pools: $_" }
}
