Function Remove-DevOpsTeam
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][string]$ProjectId,
        [Parameter(Mandatory)][string]$TeamId,
        [Parameter()][string]$ApiVersion = '7.1'
    )
    $params = @{
        Uri    = '{0}/_apis/projects/{1}/teams/{2}?api-version={3}' -f $ApiUri, $ProjectId, $TeamId, $ApiVersion
        Method = 'DELETE'
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[Remove-DevOpsTeam] Failed to remove team '$TeamId': $_" }
}
