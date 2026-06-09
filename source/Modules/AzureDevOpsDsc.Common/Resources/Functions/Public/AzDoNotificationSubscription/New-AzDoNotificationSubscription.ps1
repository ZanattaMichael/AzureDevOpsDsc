Function New-AzDoNotificationSubscription
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
    Write-Verbose "[New-AzDoNotificationSubscription] Creating subscription '$SubscriptionName'."
    $channel = @{ type = $ChannelType; address = $Subscriber }
    $params = @{
        ApiUri      = 'https://dev.azure.com/{0}/' -f (Get-AzDoOrganizationName)
        EventType   = $EventType
        Channel     = $channel
        Description = $SubscriptionName
        Filter      = $Filter
    }
    $value = New-DevOpsNotificationSubscription @params
    Add-CacheItem -Key $SubscriptionName -Value $value -Type 'LiveNotificationSubscriptions'
    Export-CacheObject -CacheType 'LiveNotificationSubscriptions' -Content $AzDoLiveNotificationSubscriptions
    Refresh-CacheObject -CacheType 'LiveNotificationSubscriptions'
}
