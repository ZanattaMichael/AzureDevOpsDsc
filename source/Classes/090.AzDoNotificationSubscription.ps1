<#
.SYNOPSIS
    DSC resource for managing Azure DevOps notification subscriptions.
.DESCRIPTION
    This resource manages Azure DevOps notification subscriptions, which deliver alerts about
    project events (builds, pull requests, work items, etc.) to email addresses or other
    subscribers.

.PARAMETER SubscriptionName
    A descriptive name for the subscription. This property is mandatory and serves as a key property for the resource.

.PARAMETER EventType
    The type of event to subscribe to. This is a key property. Common values include ms.vss-build.build-completed-failed-id, ms.vss-code.git-push, and ms.vss-code.git-pullrequest-created.

.PARAMETER ChannelType
    The delivery channel for notifications. Common values: EmailHtml, EmailPlainText.

.PARAMETER Subscriber
    The email address or group descriptor of the notification recipient. This is a mandatory property.

.PARAMETER ProjectName
    The project to scope the subscription to. If omitted, applies organization-wide.

.PARAMETER Filter
    A hashtable specifying event filter criteria.

.PARAMETER Enabled
    Whether the subscription is active. Defaults to $true.

#>

[DscResource()]
class AzDoNotificationSubscription : AzDevOpsDscResourceBase
{
    [DscProperty(Key, Mandatory)]
    [System.String]$SubscriptionName

    [DscProperty(Mandatory)]
    [System.String]$EventType

    [DscProperty(Mandatory)]
    [System.String]$ChannelType

    [DscProperty(Mandatory)]
    [System.String]$Subscriber

    [DscProperty()]
    [System.String]$ProjectName

    [DscProperty()]
    [HashTable]$Filter

    [DscProperty()]
    [System.Boolean]$Enabled = $true

    AzDoNotificationSubscription()
    {
        $this.Construct()
    }

    [void] Set() { ([AzDevOpsDscResourceBase]$this).Set() }
    [System.Boolean] Test() { return ([AzDevOpsDscResourceBase]$this).Test() }
    [AzDoNotificationSubscription] Get()
    {
        return [AzDoNotificationSubscription]$($this.GetDscCurrentStateProperties())
    }

    hidden [System.String[]]GetDscResourcePropertyNamesWithNoSetSupport()
    {
        return @()
    }

    hidden [Hashtable]GetDscCurrentStateProperties([PSCustomObject]$CurrentResourceObject)
    {
        $properties = @{ Ensure = [Ensure]::Absent }
        if ($null -eq $CurrentResourceObject) { return $properties }
        $properties.SubscriptionName = $CurrentResourceObject.SubscriptionName
        $properties.EventType        = $CurrentResourceObject.EventType
        $properties.ChannelType      = $CurrentResourceObject.ChannelType
        $properties.Subscriber       = $CurrentResourceObject.Subscriber
        $properties.ProjectName      = $CurrentResourceObject.ProjectName
        $properties.Filter           = $CurrentResourceObject.Filter
        $properties.Enabled          = $CurrentResourceObject.Enabled
        $properties.LookupResult     = $CurrentResourceObject.LookupResult
        $properties.Ensure           = $CurrentResourceObject.Ensure
        return $properties
    }
}
