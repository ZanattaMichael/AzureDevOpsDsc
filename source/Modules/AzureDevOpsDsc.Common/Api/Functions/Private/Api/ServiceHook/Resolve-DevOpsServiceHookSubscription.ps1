<#
.SYNOPSIS
Finds an existing service hook subscription matching a desired event/consumer tuple.

.DESCRIPTION
Service hook subscriptions have no user-assigned name; they are identified by a server-generated id.
This helper lists the organization's subscriptions and returns the one matching the natural identity
tuple: publisherId + eventType + consumerId + consumerActionId, plus the consumer 'url' input when one
is supplied (the discriminator for webhook-style consumers that may share an event type).

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER PublisherId
The publisher id (e.g. 'tfs', 'rm').

.PARAMETER EventType
The event type (e.g. 'git.push', 'build.complete').

.PARAMETER ConsumerId
The consumer id (e.g. 'webHooks').

.PARAMETER ConsumerActionId
The consumer action id (e.g. 'httpRequest').

.PARAMETER ConsumerInputs
The desired consumer inputs; the 'url' value (when present) is used as an additional discriminator.

.OUTPUTS
The matching subscription object, or $null.
#>
function Resolve-DevOpsServiceHookSubscription
{
    [CmdletBinding()]
    [OutputType([System.Object])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$Organization,

        [Parameter(Mandatory = $true)]
        [string]$PublisherId,

        [Parameter(Mandatory = $true)]
        [string]$EventType,

        [Parameter(Mandatory = $true)]
        [string]$ConsumerId,

        [Parameter(Mandatory = $true)]
        [string]$ConsumerActionId,

        [Parameter()]
        [hashtable]$ConsumerInputs
    )

    $desiredUrl = if ($ConsumerInputs) { $ConsumerInputs['url'] } else { $null }

    List-DevOpsServiceHookSubscription -Organization $Organization | Where-Object {
        ($_.publisherId -eq $PublisherId) -and
        ($_.eventType -eq $EventType) -and
        ($_.consumerId -eq $ConsumerId) -and
        ($_.consumerActionId -eq $ConsumerActionId) -and
        ((-not $desiredUrl) -or ($_.consumerInputs.url -eq $desiredUrl))
    } | Select-Object -First 1
}
