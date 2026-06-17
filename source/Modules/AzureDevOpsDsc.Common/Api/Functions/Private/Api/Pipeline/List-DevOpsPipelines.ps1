Function List-DevOpsPipelines
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][string]$ProjectName,
        [Parameter()][string]$ApiVersion = '7.1'
    )
    $params = @{
        Uri    = '{0}/{1}/_apis/pipelines?api-version={2}' -f $ApiUri.TrimEnd('/'), $ProjectName, $ApiVersion
        Method = 'GET'
    }
    try   { return (Invoke-AzDevOpsApiRestMethod @params).value }
    catch { Throw "[List-DevOpsPipelines] Failed to list pipelines for '$ProjectName': $_" }
}
