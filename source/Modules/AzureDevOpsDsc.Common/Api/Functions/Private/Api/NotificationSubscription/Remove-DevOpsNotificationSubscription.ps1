Function Remove-DevOpsNotificationSubscription
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][string]$SubscriptionId,
        [Parameter()][string]$ApiVersion = '7.1-preview.1'
    )
    $params = @{
        Uri    = '{0}/_apis/notification/subscriptions/{1}?api-version={2}' -f $ApiUri.TrimEnd('/'), $SubscriptionId, $ApiVersion
        Method = 'DELETE'
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[Remove-DevOpsNotificationSubscription] Failed to remove notification subscription '$SubscriptionId': $_" }
}
