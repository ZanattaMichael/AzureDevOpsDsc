Function Remove-AzDoNotificationSubscription
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$SubscriptionName,
        [Parameter(Mandatory = $true)][string]$EventType,
        [Parameter(Mandatory = $true)][string]$ChannelType,
        [Parameter(Mandatory = $true)][string]$Subscriber,
        [Parameter()][string]$ProjectName,
        [Parameter()][HashTable]$Filter,
        [Parameter()][bool]$Enabled = $true,
        [Parameter()][HashTable]$LookupResult,
        [Parameter()][Ensure]$Ensure,
        [Parameter()][System.Management.Automation.SwitchParameter]$Force
    )
    Write-Verbose "[Remove-AzDoNotificationSubscription] Removing subscription '$SubscriptionName'."
    $sub = Get-CacheItem -Key $SubscriptionName -Type 'LiveNotificationSubscriptions'
    if (-not $sub) { Write-Error "[Remove-AzDoNotificationSubscription] Subscription not found."; return }
    $params = @{
        ApiUri         = 'https://dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
        SubscriptionId = $sub.id
    }
    Remove-DevOpsNotificationSubscription @params
    Remove-CacheItem -Key $SubscriptionName -Type 'LiveNotificationSubscriptions'
    Export-CacheObject -CacheType 'LiveNotificationSubscriptions' -Content $AzDoLiveNotificationSubscriptions
}
