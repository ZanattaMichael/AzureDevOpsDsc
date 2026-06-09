Function New-DevOpsAgentPool
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][string]$PoolName,
        [Parameter()][ValidateSet('automation','deployment')][string]$PoolType = 'automation',
        [Parameter()][bool]$AutoProvision = $false,
        [Parameter()][bool]$AutoUpdate    = $true,
        [Parameter()][bool]$IsHosted      = $false,
        [Parameter()][string]$ApiVersion  = '7.1'
    )
    $params = @{
        Uri         = '{0}/_apis/distributedtask/pools?api-version={1}' -f $ApiUri, $ApiVersion
        Method      = 'POST'
        ContentType = 'application/json'
        Body        = @{
            name          = $PoolName
            poolType      = $PoolType
            autoProvision = $AutoProvision
            autoUpdate    = $AutoUpdate
            isHosted      = $IsHosted
        } | ConvertTo-Json
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[New-DevOpsAgentPool] Failed to create pool '$PoolName': $_" }
}
