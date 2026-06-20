<#
.SYNOPSIS
Retrieves the current state of an Azure DevOps service hook subscription.

.DESCRIPTION
Matches a live service hook subscription by its natural identity tuple (publisher/event/consumer) and
reports whether it exists and whether the user-specified publisher/consumer inputs match. Only the input
keys supplied in the configuration are compared — the API adds server-managed keys (hostId, etc.) that
are ignored.

.PARAMETER Name
A logical name for the subscription. This is the DSC key; it is not sent to Azure DevOps.

.PARAMETER ProjectName
Optional project name; when supplied its id is added to the publisher inputs as 'projectId'.

.PARAMETER PublisherId
The publisher id (e.g. 'tfs', 'rm').

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

.PARAMETER LookupResult
A hashtable to store the lookup result.

.PARAMETER Ensure
Specifies the desired state.

.OUTPUTS
System.Collections.Hashtable
#>
function Get-AzDoServiceHook
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]$Name,

        [Parameter()]
        [System.String]$ProjectName,

        [Parameter()]
        [System.String]$PublisherId,

        [Parameter()]
        [System.String]$EventType,

        [Parameter()]
        [System.String]$ConsumerId,

        [Parameter()]
        [System.String]$ConsumerActionId,

        [Parameter()]
        [HashTable]$ConsumerInputs,

        [Parameter()]
        [HashTable]$PublisherInputs,

        [Parameter()]
        [System.String]$ResourceVersion = '1.0',

        [Parameter()]
        [HashTable]$LookupResult,

        [Parameter()]
        [Ensure]$Ensure
    )

    Write-Verbose "[Get-AzDoServiceHook] Started."

    $OrganizationName = (Get-AzDoOrganizationName)

    $result = @{
        Ensure            = [Ensure]::Absent
        Name              = $Name
        propertiesChanged = @()
        status            = $null
    }

    $resolveParams = @{
        Organization     = $OrganizationName
        PublisherId      = $PublisherId
        EventType        = $EventType
        ConsumerId       = $ConsumerId
        ConsumerActionId = $ConsumerActionId
        ConsumerInputs   = $ConsumerInputs
    }
    $subscription = Resolve-DevOpsServiceHookSubscription @resolveParams

    if ($null -eq $subscription)
    {
        Write-Verbose "[Get-AzDoServiceHook] Subscription '$Name' not found."
        $result.status = [DSCGetSummaryState]::NotFound
        return $result
    }

    $result.subscriptionId = $subscription.id

    # Compare only the consumer/publisher input keys the user specified; the API adds server-managed keys.
    if ($ConsumerInputs)
    {
        foreach ($key in $ConsumerInputs.Keys)
        {
            if ([string]$subscription.consumerInputs.$key -ne [string]$ConsumerInputs[$key])
            {
                $result.propertiesChanged += "consumerInputs.$key"
            }
        }
    }
    if ($PublisherInputs)
    {
        foreach ($key in $PublisherInputs.Keys)
        {
            if ([string]$subscription.publisherInputs.$key -ne [string]$PublisherInputs[$key])
            {
                $result.propertiesChanged += "publisherInputs.$key"
            }
        }
    }

    if ($result.propertiesChanged.Count -gt 0)
    {
        $result.status = [DSCGetSummaryState]::Changed
        Write-Verbose "[Get-AzDoServiceHook] Subscription '$Name' has drifted: $($result.propertiesChanged -join ', ')"
    }
    else
    {
        $result.status = [DSCGetSummaryState]::Unchanged
        Write-Verbose "[Get-AzDoServiceHook] Subscription '$Name' is in the desired state."
    }

    return $result
}
