Function New-DevOpsAuditStream
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][ValidateSet('AzureMonitorLogs','Splunk','AzureEventGrid','AzureEventHub')][string]$ConsumerType,
        [Parameter(Mandatory)][hashtable]$ConsumerInputs,
        [Parameter()][bool]$DaysToBackfill = $false,
        [Parameter()][string]$ApiVersion = '7.1-preview.1'
    )
    $params = @{
        Uri         = '{0}/_apis/audit/streams?daysToBackfill={1}&api-version={2}' -f $ApiUri.TrimEnd('/'), ([int]$DaysToBackfill), $ApiVersion
        Method      = 'POST'
        ContentType = 'application/json'
        Body        = @{
            consumerType   = $ConsumerType
            consumerInputs = $ConsumerInputs
        } | ConvertTo-Json -Depth 5
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[New-DevOpsAuditStream] Failed to create audit stream: $_" }
}
