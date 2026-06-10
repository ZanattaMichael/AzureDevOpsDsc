Function Remove-DevOpsServiceConnection
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][string]$ProjectName,
        [Parameter(Mandatory)][string]$ServiceConnectionId,
        [Parameter()][bool]$Deep = $false,
        [Parameter()][string]$ApiVersion = '7.1-preview.4'
    )
    $params = @{
        Uri    = '{0}/{1}/_apis/serviceendpoint/endpoints/{2}?deep={3}&api-version={4}' -f $ApiUri.TrimEnd('/'), $ProjectName, $ServiceConnectionId, $Deep.ToString().ToLower(), $ApiVersion
        Method = 'DELETE'
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[Remove-DevOpsServiceConnection] Failed to remove service connection '$ServiceConnectionId': $_" }
}
