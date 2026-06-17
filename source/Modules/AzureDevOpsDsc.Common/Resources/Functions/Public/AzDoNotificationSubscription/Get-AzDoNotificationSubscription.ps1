Function Get-AzDoNotificationSubscription
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
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
    Write-Verbose "[Get-AzDoNotificationSubscription] Started."
    $result = @{ Ensure = [Ensure]::Absent; propertiesChanged = @(); status = $null }
    $sub = Get-CacheItem -Key $SubscriptionName -Type 'LiveNotificationSubscriptions'
    if ($sub) { $result.liveCache = $sub; $result.status = [DSCGetSummaryState]::Unchanged }
    else       { $result.status = [DSCGetSummaryState]::NotFound }
    return $result
}
