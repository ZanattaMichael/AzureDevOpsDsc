Function Set-DevOpsNotificationSubscription
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][string]$SubscriptionId,
        [Parameter(Mandatory)][string]$EventType,
        [Parameter(Mandatory)][hashtable]$Channel,
        [Parameter()][hashtable]$Filter,
        [Parameter()][string]$Description,
        [Parameter()][string]$ApiVersion = '7.1-preview.1'
    )
    $body = @{
        eventType   = $EventType
        channel     = $Channel
        description = $Description
    }
    if ($Filter) { $body['filter'] = $Filter }
    $params = @{
        Uri         = '{0}/_apis/notification/subscriptions/{1}?api-version={2}' -f $ApiUri, $SubscriptionId, $ApiVersion
        Method      = 'PUT'
        ContentType = 'application/json'
        Body        = $body | ConvertTo-Json -Depth 10
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[Set-DevOpsNotificationSubscription] Failed to update notification subscription '$SubscriptionId': $_" }
}
