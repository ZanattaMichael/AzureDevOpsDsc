<#
.SYNOPSIS
Reads the Azure DevOps organization policies.

.DESCRIPTION
The organization policy API has no read route: `_apis/OrganizationPolicy/Policies/{policyName}`
accepts PATCH only and answers GET with 405 Method Not Allowed. The *Organization settings ->
Policies* page reads the policies from the `ms.vss-org-web.collection-admin-policy-data-provider`
data provider instead, and so does this function.

The data provider is queried through `_apis/Contribution/HierarchyQuery`. If that returns no policy
data, the function falls back to the page's own data route
(`_settings/organizationPolicy?__rt=fps&__ver=2`). Both return the policies grouped by page section
(`applicationConnection`, `security`, `user`, ...), each entry carrying a `policy` object with a
`name` and a `value` (and usually an `effectiveValue`). The groups are flattened, so the caller
gets one policy object per policy, exactly as the service returned it.

.PARAMETER ApiUri
The base organization URI, e.g. 'https://dev.azure.com/myorg/'.

.PARAMETER PolicyName
Optional. Returns only the policies with this name, e.g. 'Policy.LogAuditEvents'.

.PARAMETER ApiVersion
The REST API version used for the HierarchyQuery call. Defaults to '5.0-preview.1'.

.EXAMPLE
Get-DevOpsOrganizationPolicy -ApiUri 'https://dev.azure.com/myorg/'

.EXAMPLE
Get-DevOpsOrganizationPolicy -ApiUri 'https://dev.azure.com/myorg/' -PolicyName 'Policy.LogAuditEvents'
#>
function Get-DevOpsOrganizationPolicy
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter()][string]$PolicyName,
        [Parameter()][string]$ApiVersion = '5.0-preview.1'
    )

    $dataProviderId = 'ms.vss-org-web.collection-admin-policy-data-provider'
    $baseUri        = $ApiUri.TrimEnd('/')
    $failures       = @()
    $groups         = $null

    # First choice: the contribution data provider API.
    $hierarchyQuery = @{
        contributionIds     = @($dataProviderId)
        dataProviderContext = @{
            properties = @{
                sourcePage = @{
                    url         = '{0}/_settings/organizationPolicy' -f $baseUri
                    routeId     = 'ms.vss-admin-web.collection-admin-hub-route'
                    routeValues = @{
                        adminPivot = 'organizationPolicy'
                        controller = 'ContributedPage'
                        action     = 'Execute'
                    }
                }
            }
        }
    }

    try
    {
        $params = @{
            Uri    = '{0}/_apis/Contribution/HierarchyQuery?api-version={1}' -f $baseUri, $ApiVersion
            Method = 'POST'
            Body   = $hierarchyQuery | ConvertTo-Json -Depth 10
        }
        $response = Invoke-AzDevOpsApiRestMethod @params
        $groups   = $response.dataProviders.$dataProviderId.policies
    }
    catch
    {
        $failures += "HierarchyQuery: $_"
    }

    # Fallback: the data route the settings page itself loads.
    if ($null -eq $groups)
    {
        try
        {
            $params = @{
                Uri    = '{0}/_settings/organizationPolicy?__rt=fps&__ver=2' -f $baseUri
                Method = 'GET'
            }
            $response = Invoke-AzDevOpsApiRestMethod @params
            $groups   = $response.fps.dataProviders.data.$dataProviderId.policies
        }
        catch
        {
            $failures += "settings page data: $_"
        }
    }

    if ($null -eq $groups)
    {
        $reason = if ($failures.Count -gt 0) { $failures -join '; ' } else { 'the response carried no policy data' }
        Throw "[Get-DevOpsOrganizationPolicy] Failed to retrieve organization policies: $reason"
    }

    $policies = foreach ($group in $groups.PSObject.Properties)
    {
        foreach ($entry in @($group.Value))
        {
            if ($null -ne $entry.policy) { $entry.policy }
        }
    }

    if ($PSBoundParameters.ContainsKey('PolicyName'))
    {
        $policies = $policies | Where-Object { $_.name -eq $PolicyName }
    }

    return $policies
}
