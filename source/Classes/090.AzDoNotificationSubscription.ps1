<#
.SYNOPSIS
    DSC resource for managing Azure DevOps notification subscriptions.
#>

[DscResource()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCStandardDSCFunctionsInResource', '', Justification='Test() and Set() method are inherited from base, "AzDevOpsDscResourceBase" class')]
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