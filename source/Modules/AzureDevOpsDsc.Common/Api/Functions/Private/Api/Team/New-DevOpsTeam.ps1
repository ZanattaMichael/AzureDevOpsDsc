Function New-DevOpsTeam
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][string]$ProjectId,
        [Parameter(Mandatory)][string]$TeamName,
        [Parameter()][string]$Description,
        [Parameter()][string]$ApiVersion = '7.1'
    )
    $params = @{
        Uri         = '{0}/_apis/projects/{1}/teams?api-version={2}' -f $ApiUri, $ProjectId, $ApiVersion
        Method      = 'POST'
        ContentType = 'application/json'
        Body        = @{ name = $TeamName; description = $Description } | ConvertTo-Json
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[New-DevOpsTeam] Failed to create team '$TeamName': $_" }
}
