Function List-DevOpsCheckConfigurations
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][string]$ProjectName,
        [Parameter()][string]$ResourceType,
        [Parameter()][string]$ResourceId,
        [Parameter()][string]$ApiVersion = '7.1-preview.1'
    )
    $uri = '{0}/{1}/_apis/pipelines/checks/configurations?api-version={2}' -f $ApiUri.TrimEnd('/'), $ProjectName, $ApiVersion
    if ($ResourceType) { $uri += '&resourceType={0}' -f $ResourceType }
    if ($ResourceId)   { $uri += '&resourceId={0}'   -f $ResourceId }
    $params = @{
        Uri    = $uri
        Method = 'GET'
    }
    try   { return (Invoke-AzDevOpsApiRestMethod @params).value }
    catch { Throw "[List-DevOpsCheckConfigurations] Failed to list check configurations for '$ProjectName': $_" }
}
