<#
.SYNOPSIS
Reads the Azure DevOps organization policies.

.DESCRIPTION
The *Organization settings -> Policies* page reads the policies from the
`ms.vss-org-web.collection-admin-policy-data-provider` data provider, and so does this function.

The data provider is queried through `_apis/Contribution/HierarchyQuery`. If that returns no policy
data, the function falls back to the page's own data route
(`_settings/organizationPolicy?__rt=fps&__ver=2`). Both return the policies grouped by page section
(`applicationConnection`, `security`, `user`, ...), each entry carrying a `policy` object with a
`name` and a `value` (and usually an `effectiveValue`). The groups are flattened, so the caller
gets one policy object per policy, exactly as the service returned it.

Both of those are the web page's routes, and can answer a service principal or managed identity
with no policy data at all. When they do and `PolicyName` is given, each named policy is read from
the policy API (`_apis/OrganizationPolicy/Policies/{name}`) as a last resort, on the organization
host and then on its SPS host (`vssps.dev.azure.com`). That GET needs a `defaultValue` query
parameter - the value to report for a policy that was never set - and answers 405 without one. If
every route comes back empty, the error says what each one returned.

.PARAMETER ApiUri
The base organization URI, e.g. 'https://dev.azure.com/myorg/'.

.PARAMETER PolicyName
Optional. Returns only the policies with these names, e.g. 'Policy.LogAuditEvents'. Required for the
per-policy fallback route.

.PARAMETER DefaultValue
Optional. Policy name to the value the per-policy route reports for a policy that was never set.
A policy not listed is read with 'false'.

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
        [Parameter()][hashtable]$DefaultValue = @{},
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
        # Last resort: read each policy from the policy API, on the organization host and then on
        # the SPS host. The GET needs defaultValue; without it the service answers 405. All or
        # nothing, so a failure keeps every route's reason.
        $spsUri    = $baseUri -replace '^https://dev\.azure\.com/', 'https://vssps.dev.azure.com/'
        $readFails = @()
        $policies  = foreach ($name in $PolicyName)
        {
            $default = if ($DefaultValue.ContainsKey($name)) { [string]$DefaultValue[$name] } else { 'false' }
            $policy  = $null
            $reasons = @()

            foreach ($hostUri in @($baseUri, $spsUri | Select-Object -Unique))
            {
                try
                {
                    $params = @{
                        Uri    = '{0}/_apis/OrganizationPolicy/Policies/{1}?defaultValue={2}&api-version={3}' -f $hostUri, $name, [uri]::EscapeDataString($default), $ApiVersion
                        Method = 'GET'
                    }
                    $policy = Invoke-AzDevOpsApiRestMethod @params
                    break
                }
                catch
                {
                    $reasons += "$($hostUri): $_"
                }
            }

            if ($null -eq $policy)
            {
                $readFails += "policy API read ($name): $($reasons -join ' | ')"
                continue
            }

            if ($null -eq $policy.PSObject.Properties['name'])
            {
                $policy | Add-Member -NotePropertyName name -NotePropertyValue $name
            }
            $policy
        }

        if ($readFails.Count -gt 0)
        {
            $failures += $readFails
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
