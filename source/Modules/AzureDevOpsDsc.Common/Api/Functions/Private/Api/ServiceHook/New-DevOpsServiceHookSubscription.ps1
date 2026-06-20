<#
.SYNOPSIS
Creates a service hook subscription in Azure DevOps.

.DESCRIPTION
Creates a subscription via the Service Hooks REST API
(POST https://dev.azure.com/{org}/_apis/hooks/subscriptions).

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER Subscription
A hashtable describing the subscription (publisherId, eventType, resourceVersion, consumerId,
consumerActionId, publisherInputs, consumerInputs).

.PARAMETER ApiVersion
The REST API version to use. Defaults to '7.1'.

.EXAMPLE
New-DevOpsServiceHookSubscription -Organization 'myorg' -Subscription $sub
#>
function New-DevOpsServiceHookSubscription
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$Organization,

        [Parameter(Mandatory = $true)]
        [hashtable]$Subscription,

        [Parameter()]
        [string]$ApiVersion = '7.1'
    )

    $params = @{
        Uri    = 'https://dev.azure.com/{0}/_apis/hooks/subscriptions?api-version={1}' -f $Organization, $ApiVersion
        Method = 'POST'
        Body   = $Subscription | ConvertTo-Json -Depth 6
    }

    if (-not $PSCmdlet.ShouldProcess($Subscription.eventType, 'Create service hook subscription'))
    {
        return
    }

    try
    {
        return Invoke-AzDevOpsApiRestMethod @params
    }
    catch
    {
        throw "[New-DevOpsServiceHookSubscription] Failed to create subscription in '$Organization': $_"
    }
}
