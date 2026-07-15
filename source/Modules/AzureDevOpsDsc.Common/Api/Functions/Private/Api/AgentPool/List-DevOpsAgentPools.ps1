Function List-DevOpsAgentPools
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter()][string]$ApiVersion = '7.1'
    )
    # The pools API excludes 'deployment' poolType pools unless explicitly requested via
    # ?poolType=deployment - and that filter excludes everything else in turn. Query both
    # and merge so callers see the full live set regardless of pool type.
    $baseUri = '{0}/_apis/distributedtask/pools' -f $ApiUri.TrimEnd('/')
    try
    {
        $defaultPools    = (Invoke-AzDevOpsApiRestMethod -Uri ('{0}?api-version={1}' -f $baseUri, $ApiVersion) -Method 'GET').value
        $deploymentPools = (Invoke-AzDevOpsApiRestMethod -Uri ('{0}?poolType=deployment&api-version={1}' -f $baseUri, $ApiVersion) -Method 'GET').value
        return @($defaultPools) + @($deploymentPools)
    }
    catch { Throw "[List-DevOpsAgentPools] Failed to list agent pools: $_" }
}
