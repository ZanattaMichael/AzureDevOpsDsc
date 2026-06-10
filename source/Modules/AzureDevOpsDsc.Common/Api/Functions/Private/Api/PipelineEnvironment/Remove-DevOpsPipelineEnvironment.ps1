Function Remove-DevOpsPipelineEnvironment
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][string]$ProjectName,
        [Parameter(Mandatory)][int]$EnvironmentId,
        [Parameter()][string]$ApiVersion = '7.1-preview.1'
    )
    $params = @{
        Uri    = '{0}/{1}/_apis/distributedtask/environments/{2}?api-version={3}' -f $ApiUri.TrimEnd('/'), $ProjectName, $EnvironmentId, $ApiVersion
        Method = 'DELETE'
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[Remove-DevOpsPipelineEnvironment] Failed to remove environment '$EnvironmentId': $_" }
}
