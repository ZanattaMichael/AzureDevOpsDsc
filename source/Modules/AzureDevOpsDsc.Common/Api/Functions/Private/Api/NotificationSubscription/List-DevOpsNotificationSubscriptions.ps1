Function List-DevOpsNotificationSubscriptions
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter()][string]$ApiVersion = '7.1-preview.1'
    )
    $params = @{
        Uri    = '{0}/_apis/notification/subscriptions?api-version={1}' -f $ApiUri.TrimEnd('/'), $ApiVersion
        Method = 'GET'
    }
    try   { return (Invoke-AzDevOpsApiRestMethod @params).value }
    catch { Throw "[List-DevOpsNotificationSubscriptions] Failed to list notification subscriptions: $_" }
}
