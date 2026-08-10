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
    # useCustomAddress must be set or Azure DevOps ignores 'address' entirely and falls back to
    # the (unspecified, defaulting to the calling identity's) subscriber's own notification
    # preferences - which fails with "requires a valid e-mail address" for any identity without a
    # configured mailbox (e.g. a Managed Identity/service principal).
    $channel = @{ type = $ChannelType; address = $Subscriber; useCustomAddress = $true }
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
