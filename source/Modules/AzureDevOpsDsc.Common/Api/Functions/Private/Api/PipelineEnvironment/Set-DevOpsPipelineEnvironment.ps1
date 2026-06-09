Function Set-DevOpsPipelineEnvironment
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][string]$ProjectName,
        [Parameter(Mandatory)][int]$EnvironmentId,
        [Parameter()][string]$EnvironmentName,
        [Parameter()][string]$Description,
        [Parameter()][string]$ApiVersion = '7.1-preview.1'
    )
    $params = @{
        Uri         = '{0}/{1}/_apis/distributedtask/environments/{2}?api-version={3}' -f $ApiUri, $ProjectName, $EnvironmentId, $ApiVersion
        Method      = 'PATCH'
        ContentType = 'application/json'
        Body        = @{ name = $EnvironmentName; description = $Description } | ConvertTo-Json
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[Set-DevOpsPipelineEnvironment] Failed to update environment '$EnvironmentId': $_" }
}
