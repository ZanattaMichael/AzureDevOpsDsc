<#
.SYNOPSIS
Removes a service hook subscription from Azure DevOps.

.DESCRIPTION
Deletes a subscription via the Service Hooks REST API
(DELETE https://dev.azure.com/{org}/_apis/hooks/subscriptions/{id}).

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER SubscriptionId
The id (GUID) of the subscription to delete.

.PARAMETER ApiVersion
The REST API version to use. Defaults to '7.1'.

.EXAMPLE
Remove-DevOpsServiceHookSubscription -Organization 'myorg' -SubscriptionId '...'
#>
function Remove-DevOpsServiceHookSubscription
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$Organization,

        [Parameter(Mandatory = $true)]
        [string]$SubscriptionId,

        [Parameter()]
        [string]$ApiVersion = '7.1'
    )

    $params = @{
        Uri    = 'https://dev.azure.com/{0}/_apis/hooks/subscriptions/{1}?api-version={2}' -f $Organization, $SubscriptionId, $ApiVersion
        Method = 'DELETE'
    }

    if (-not $PSCmdlet.ShouldProcess($SubscriptionId, 'Remove service hook subscription'))
    {
        return
    }

    try
    {
        return Invoke-AzDevOpsApiRestMethod @params
    }
    catch
    {
        throw "[Remove-DevOpsServiceHookSubscription] Failed to remove subscription '$SubscriptionId' in '$Organization': $_"
    }
}
