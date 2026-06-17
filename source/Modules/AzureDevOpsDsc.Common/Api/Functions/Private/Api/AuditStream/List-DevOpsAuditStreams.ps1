Function List-DevOpsAuditStreams
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter()][string]$ApiVersion = '7.1-preview.1'
    )
    $params = @{
        Uri    = '{0}/_apis/audit/streams?api-version={1}' -f $ApiUri.TrimEnd('/'), $ApiVersion
        Method = 'GET'
    }
    try   { return (Invoke-AzDevOpsApiRestMethod @params).value }
    catch { Throw "[List-DevOpsAuditStreams] Failed to list audit streams: $_" }
}
