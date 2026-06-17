Function Remove-DevOpsPipeline
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][string]$ProjectName,
        [Parameter(Mandatory)][int]$PipelineId,
        [Parameter()][string]$ApiVersion = '7.1'
    )
    # The Pipelines API does not expose a DELETE endpoint; use the Build Definition API instead
    $params = @{
        Uri    = '{0}/{1}/_apis/build/definitions/{2}?api-version={3}' -f $ApiUri.TrimEnd('/'), $ProjectName, $PipelineId, $ApiVersion
        Method = 'DELETE'
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[Remove-DevOpsPipeline] Failed to remove pipeline '$PipelineId': $_" }
}
