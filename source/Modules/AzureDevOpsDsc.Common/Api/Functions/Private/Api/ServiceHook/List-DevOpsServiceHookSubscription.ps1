<#
.SYNOPSIS
Lists the service hook subscriptions in an Azure DevOps organization.

.DESCRIPTION
Retrieves all service hook subscriptions via the Service Hooks REST API
(GET https://dev.azure.com/{org}/_apis/hooks/subscriptions).

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ApiVersion
The REST API version to use. Defaults to '7.1'.

.OUTPUTS
An array of subscription objects, or an empty array.

.EXAMPLE
List-DevOpsServiceHookSubscription -Organization 'myorg'
#>
function List-DevOpsServiceHookSubscription
{
    [CmdletBinding()]
    [OutputType([System.Object[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$Organization,

        [Parameter()]
        [string]$ApiVersion = '7.1'
    )

    $params = @{
        Uri    = 'https://dev.azure.com/{0}/_apis/hooks/subscriptions?api-version={1}' -f $Organization, $ApiVersion
        Method = 'Get'
    }

    $response = Invoke-AzDevOpsApiRestMethod @params
    if ($null -eq $response.value)
    {
        return @()
    }

    return $response.value
}
