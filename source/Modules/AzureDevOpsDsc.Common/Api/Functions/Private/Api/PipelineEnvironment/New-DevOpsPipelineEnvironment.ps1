Function New-DevOpsPipelineEnvironment
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][string]$ProjectName,
        [Parameter(Mandatory)][string]$EnvironmentName,
        [Parameter()][string]$Description,
        [Parameter()][string]$ApiVersion = '7.1-preview.1'
    )
    $params = @{
        Uri         = '{0}/{1}/_apis/distributedtask/environments?api-version={2}' -f $ApiUri.TrimEnd('/'), $ProjectName, $ApiVersion
        Method      = 'POST'
        ContentType = 'application/json'
        Body        = @{ name = $EnvironmentName; description = $Description } | ConvertTo-Json
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[New-DevOpsPipelineEnvironment] Failed to create environment '$EnvironmentName': $_" }
}
