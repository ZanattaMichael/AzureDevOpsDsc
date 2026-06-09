Function Set-DevOpsTeam
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][string]$ProjectId,
        [Parameter(Mandatory)][string]$TeamId,
        [Parameter()][string]$TeamName,
        [Parameter()][string]$Description,
        [Parameter()][string]$ApiVersion = '7.1'
    )
    $params = @{
        Uri         = '{0}/_apis/projects/{1}/teams/{2}?api-version={3}' -f $ApiUri, $ProjectId, $TeamId, $ApiVersion
        Method      = 'PATCH'
        ContentType = 'application/json'
        Body        = @{ name = $TeamName; description = $Description } | ConvertTo-Json
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[Set-DevOpsTeam] Failed to update team '$TeamId': $_" }
}
