<#
.SYNOPSIS
Replaces an existing service hook subscription in Azure DevOps.

.DESCRIPTION
Updates a subscription via the Service Hooks REST API
(PUT https://dev.azure.com/{org}/_apis/hooks/subscriptions/{id}).

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER SubscriptionId
The id (GUID) of the subscription to replace.

.PARAMETER Subscription
A hashtable describing the desired subscription state.

.PARAMETER ApiVersion
The REST API version to use. Defaults to '7.1'.

.EXAMPLE
Update-DevOpsServiceHookSubscription -Organization 'myorg' -SubscriptionId '...' -Subscription $sub
#>
function Update-DevOpsServiceHookSubscription
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$Organization,

        [Parameter(Mandatory = $true)]
        [string]$SubscriptionId,

        [Parameter(Mandatory = $true)]
        [hashtable]$Subscription,

        [Parameter()]
        [string]$ApiVersion = '7.1'
    )

    # The Replace (PUT) endpoint expects the id in the body as well as the route.
    $body = $Subscription.Clone()
    $body.id = $SubscriptionId

    $params = @{
        Uri    = 'https://dev.azure.com/{0}/_apis/hooks/subscriptions/{1}?api-version={2}' -f $Organization, $SubscriptionId, $ApiVersion
        Method = 'PUT'
        Body   = $body | ConvertTo-Json -Depth 6
    }

    if (-not $PSCmdlet.ShouldProcess($SubscriptionId, 'Update service hook subscription'))
    {
        return
    }

    try
    {
        return Invoke-AzDevOpsApiRestMethod @params
    }
    catch
    {
        throw "[Update-DevOpsServiceHookSubscription] Failed to update subscription '$SubscriptionId' in '$Organization': $_"
    }
}
