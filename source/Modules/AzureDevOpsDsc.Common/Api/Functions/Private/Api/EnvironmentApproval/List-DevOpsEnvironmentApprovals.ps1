Function List-DevOpsEnvironmentApprovals
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][string]$ProjectName,
        [Parameter()][int]$EnvironmentId,
        [Parameter()][string]$ApiVersion = '7.1-preview.1'
    )
    $uri = '{0}/{1}/_apis/pipelines/checks/configurations?api-version={2}' -f $ApiUri, $ProjectName, $ApiVersion
    if ($EnvironmentId) { $uri += '&resourceType=environment&resourceId={0}' -f $EnvironmentId }
    $params = @{
        Uri    = $uri
        Method = 'GET'
    }
    try   { return (Invoke-AzDevOpsApiRestMethod @params).value }
    catch { Throw "[List-DevOpsEnvironmentApprovals] Failed to list approvals for environment '$EnvironmentId': $_" }
}
