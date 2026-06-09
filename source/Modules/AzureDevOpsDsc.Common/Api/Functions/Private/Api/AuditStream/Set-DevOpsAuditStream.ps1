Function Set-DevOpsAuditStream
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][int]$StreamId,
        [Parameter(Mandatory)][ValidateSet('enabled','disabled')][string]$Status,
        [Parameter()][string]$ApiVersion = '7.1-preview.1'
    )
    $params = @{
        Uri         = '{0}/_apis/audit/streams/{1}?status={2}&api-version={3}' -f $ApiUri, $StreamId, $Status, $ApiVersion
        Method      = 'PUT'
        ContentType = 'application/json'
        Body        = '{}'
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[Set-DevOpsAuditStream] Failed to update audit stream '$StreamId': $_" }
}
