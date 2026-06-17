Function Remove-DevOpsServiceConnection
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        # Project GUID the endpoint should be removed from. Endpoint deletion is an
        # organization-level operation that takes the projects via a 'projectIds' query
        # parameter; the project-scoped URL returns 405 (Method Not Allowed) for DELETE.
        [Parameter(Mandatory)][string]$ProjectId,
        [Parameter(Mandatory)][string]$ServiceConnectionId,
        [Parameter()][bool]$Deep = $false,
        [Parameter()][string]$ApiVersion = '7.1-preview.4'
    )
    $params = @{
        Uri    = '{0}/_apis/serviceendpoint/endpoints/{1}?projectIds={2}&deep={3}&api-version={4}' -f $ApiUri.TrimEnd('/'), $ServiceConnectionId, $ProjectId, $Deep.ToString().ToLower(), $ApiVersion
        Method = 'DELETE'
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[Remove-DevOpsServiceConnection] Failed to remove service connection '$ServiceConnectionId': $_" }
}
