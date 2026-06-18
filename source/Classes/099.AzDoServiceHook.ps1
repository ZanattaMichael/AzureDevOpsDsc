<#
.SYNOPSIS
    DSC resource for managing Azure DevOps service hook subscriptions.

.DESCRIPTION
    The AzDoServiceHook resource creates and manages service hook subscriptions (e.g. webhooks to
    external systems) via the Service Hooks REST API. Subscriptions have no native name, so the Name
    property is a logical DSC handle; the live subscription is matched by its identity tuple
    (publisherId + eventType + consumerId + consumerActionId, plus the consumer 'url'). It inherits
    Test()/Set() from the AzDevOpsDscResourceBase class.

.PARAMETER Name
    A logical name for the subscription. This is the key; it is not sent to Azure DevOps.

.PARAMETER ProjectName
    Optional project to scope the subscription to; its id is added to the publisher inputs.

.PARAMETER PublisherId
    The event publisher id (e.g. 'tfs', 'rm').

.PARAMETER EventType
    The event type (e.g. 'git.push', 'build.complete').

.PARAMETER ConsumerId
    The consumer id (e.g. 'webHooks').

.PARAMETER ConsumerActionId
    The consumer action id (e.g. 'httpRequest').

.PARAMETER ConsumerInputs
    The consumer input values (e.g. @{ url = 'https://...' }).

.PARAMETER PublisherInputs
    The publisher input values (e.g. @{ repository = '...' }).

.PARAMETER ResourceVersion
    The event resource version. Defaults to '1.0'.

.EXAMPLE
    AzDoServiceHook PushWebhook
    {
        Name             = 'notify-ci-on-push'
        ProjectName      = 'MyProject'
        PublisherId      = 'tfs'
        EventType        = 'git.push'
        ConsumerId       = 'webHooks'
        ConsumerActionId = 'httpRequest'
        ConsumerInputs   = @{ url = 'https://ci.contoso.com/hook' }
        Ensure           = 'Present'
    }
#>

[DscResource()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSDSCStandardDSCFunctionsInResource', '', Justification='Test() and Set() method are inherited from base, "AzDevOpsDscResourceBase" class')]
class AzDoServiceHook : AzDevOpsDscResourceBase
{
    [DscProperty(Key)]
    [System.String]$Name

    [DscProperty()]
    [System.String]$ProjectName

    [DscProperty(Mandatory)]
    [System.String]$PublisherId

    [DscProperty(Mandatory)]
    [System.String]$EventType

    [DscProperty(Mandatory)]
    [System.String]$ConsumerId

    [DscProperty(Mandatory)]
    [System.String]$ConsumerActionId

    [DscProperty()]
    [HashTable]$ConsumerInputs

    [DscProperty()]
    [HashTable]$PublisherInputs

    [DscProperty()]
    [System.String]$ResourceVersion = '1.0'

    AzDoServiceHook()
    {
        $this.Construct()
    }

    [AzDoServiceHook] Get()
    {
        return [AzDoServiceHook]$($this.GetDscCurrentStateProperties())
    }

    hidden [System.String[]]GetDscResourcePropertyNamesWithNoSetSupport()
    {
        return @()
    }

    hidden [Hashtable]GetDscCurrentStateProperties([PSCustomObject]$CurrentResourceObject)
    {
        $properties = @{ Ensure = [Ensure]::Absent }
        if ($null -eq $CurrentResourceObject) { return $properties }
        $properties.Name             = $CurrentResourceObject.Name
        $properties.ProjectName      = $CurrentResourceObject.ProjectName
        $properties.PublisherId      = $CurrentResourceObject.PublisherId
        $properties.EventType        = $CurrentResourceObject.EventType
        $properties.ConsumerId       = $CurrentResourceObject.ConsumerId
        $properties.ConsumerActionId = $CurrentResourceObject.ConsumerActionId
        $properties.ConsumerInputs   = $CurrentResourceObject.ConsumerInputs
        $properties.PublisherInputs  = $CurrentResourceObject.PublisherInputs
        $properties.ResourceVersion  = $CurrentResourceObject.ResourceVersion
        $properties.LookupResult     = $CurrentResourceObject.LookupResult
        $properties.Ensure           = $CurrentResourceObject.Ensure
        return $properties
    }
}
