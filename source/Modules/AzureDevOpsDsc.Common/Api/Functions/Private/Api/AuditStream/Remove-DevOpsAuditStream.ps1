Function Remove-DevOpsAuditStream
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][Object]$StreamId,
        [Parameter()][string]$ApiVersion = '7.1-preview.1'
    )
    $params = @{
        Uri    = '{0}/_apis/audit/streams/{1}?api-version={2}' -f $ApiUri.TrimEnd('/'), $StreamId, $ApiVersion
        Method = 'DELETE'
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[Remove-DevOpsAuditStream] Failed to remove audit stream '$StreamId': $_" }
}
