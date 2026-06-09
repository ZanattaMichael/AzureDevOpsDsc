Function Set-AzDoNotificationSubscription
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
    Write-Verbose "[Set-AzDoNotificationSubscription] Updating subscription '$SubscriptionName'."
    $sub = Get-CacheItem -Key $SubscriptionName -Type 'LiveNotificationSubscriptions'
    if (-not $sub) { Write-Error "[Set-AzDoNotificationSubscription] Subscription not found."; return }
    $channel = @{ type = $ChannelType; address = $Subscriber }
    $params = @{
        ApiUri         = 'https://dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
        SubscriptionId = $sub.id
        EventType      = $EventType
        Channel        = $channel
        Description    = $SubscriptionName
        Filter         = $Filter
    }
    $value = Set-DevOpsNotificationSubscription @params

    if ($null -eq $value)
    {
        Write-Error "[Set-AzDoNotificationSubscription] Set-DevOpsNotificationSubscription returned null. Check authentication token and organization settings."
        return
    }
    Add-CacheItem -Key $SubscriptionName -Value $value -Type 'LiveNotificationSubscriptions'
    Export-CacheObject -CacheType 'LiveNotificationSubscriptions' -Content $AzDoLiveNotificationSubscriptions
    Refresh-CacheObject -CacheType 'LiveNotificationSubscriptions'
}
