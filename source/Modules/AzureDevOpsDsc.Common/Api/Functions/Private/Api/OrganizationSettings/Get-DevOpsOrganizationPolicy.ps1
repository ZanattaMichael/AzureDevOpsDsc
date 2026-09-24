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

Both of those are the web page's routes, and can answer a service principal or managed identity
with no policy data at all. When they do and `PolicyName` is given, each named policy is read from
the organization's SPS host (`vssps.dev.azure.com/{org}/_apis/OrganizationPolicy/Policies/{name}`)
as a last resort. If every route comes back empty, the error says what each one returned.

.PARAMETER ApiUri
The base organization URI, e.g. 'https://dev.azure.com/myorg/'.

.PARAMETER PolicyName
Optional. Returns only the policies with these names, e.g. 'Policy.LogAuditEvents'. Required for the
per-policy fallback route.

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
        [Parameter()][string[]]$PolicyName,
        [Parameter()][string]$ApiVersion = '5.0-preview.1'
    )

    $dataProviderId = 'ms.vss-org-web.collection-admin-policy-data-provider'
    $baseUri        = $ApiUri.TrimEnd('/')
    $failures       = @()
    $groups         = $null
    $policies       = $null

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

        if ($null -eq $groups)
        {
            # Say why, so a failure names the cause rather than just "no data".
            $exception = $response.dataProviderExceptions.$dataProviderId
            $failures += if ($null -ne $exception) {
                "HierarchyQuery: the data provider failed: $($exception.message)"
            } else {
                "HierarchyQuery: no policy data (data providers returned: $(@($response.dataProviders.PSObject.Properties.Name) -join ', '))"
            }
        }
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

            if ($null -eq $groups)
            {
                $failures += if ($response -is [string]) {
                    'settings page data: a non-JSON response (a sign-in page answers an identity the page does not accept)'
                } else {
                    "settings page data: no policy data (response carried: $(@($response.PSObject.Properties.Name) -join ', '))"
                }
            }
        }
        catch
        {
            $failures += "settings page data: $_"
        }
    }

    if ($null -ne $groups)
    {
        $policies = foreach ($group in $groups.PSObject.Properties)
        {
            foreach ($entry in @($group.Value))
            {
                if ($null -ne $entry.policy) { $entry.policy }
            }
        }
    }
    elseif ($PolicyName.Count -gt 0)
    {
        # Last resort: read each policy from the SPS host. The dev.azure.com policy route is
        # PATCH-only (GET answers 405). All or nothing, so a failure keeps every route's reason.
        $spsUri   = $baseUri -replace '^https://dev\.azure\.com/', 'https://vssps.dev.azure.com/'
        $spsFails = @()
        $policies = foreach ($name in $PolicyName)
        {
            try
            {
                $params = @{
                    Uri    = '{0}/_apis/OrganizationPolicy/Policies/{1}?api-version={2}' -f $spsUri, $name, $ApiVersion
                    Method = 'GET'
                }
                $policy = Invoke-AzDevOpsApiRestMethod @params
                if ($null -eq $policy.PSObject.Properties['name'])
                {
                    $policy | Add-Member -NotePropertyName name -NotePropertyValue $name
                }
                $policy
            }
            catch
            {
                $spsFails += "SPS policy read ($name): $_"
            }
        }

        if ($spsFails.Count -gt 0)
        {
            $failures += $spsFails
            $policies  = $null
        }
    }

    if ($null -eq $policies)
    {
        $reason = if ($failures.Count -gt 0) { $failures -join '; ' } else { 'the response carried no policy data' }
        Throw "[Get-DevOpsOrganizationPolicy] Failed to retrieve organization policies: $reason"
    }

    if ($PSBoundParameters.ContainsKey('PolicyName'))
    {
        $policies = $policies | Where-Object { $_.name -in $PolicyName }
    }

    return $policies
}
