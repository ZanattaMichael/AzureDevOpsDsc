Function Remove-DevOpsEnvironmentApproval
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][string]$ProjectName,
        [Parameter(Mandatory)][Object]$CheckId,
        [Parameter()][string]$ApiVersion = '7.1-preview.1'
    )
    $params = @{
        Uri    = '{0}/{1}/_apis/pipelines/checks/configurations/{2}?api-version={3}' -f $ApiUri, $ProjectName, $CheckId, $ApiVersion
        Method = 'DELETE'
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[Remove-DevOpsEnvironmentApproval] Failed to remove environment approval '$CheckId': $_" }
}
