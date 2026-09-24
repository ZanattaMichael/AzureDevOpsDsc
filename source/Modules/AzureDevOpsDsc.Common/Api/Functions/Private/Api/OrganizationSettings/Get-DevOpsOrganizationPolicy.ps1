<#
.SYNOPSIS
Reads one Azure DevOps organization policy.

.DESCRIPTION
GETs `_apis/OrganizationPolicy/Policies/{policyName}` for the given organization. Returns the raw
policy object as the API returns it (typically carrying a `.value` boolean, and for the
request-access policy an additional `.url` field).

.PARAMETER ApiUri
The base organization URI, e.g. 'https://dev.azure.com/myorg/'.

.PARAMETER PolicyName
The organization policy name, e.g. 'Policy.LogAuditEvents'.

.PARAMETER ApiVersion
The REST API version to use. Defaults to '5.0-preview.1'.

.EXAMPLE
Get-DevOpsOrganizationPolicy -ApiUri 'https://dev.azure.com/myorg/' -PolicyName 'Policy.LogAuditEvents'
#>
function Get-DevOpsOrganizationPolicy
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][string]$PolicyName,
        [Parameter()][string]$ApiVersion = '5.0-preview.1'
    )
    $params = @{
        Uri    = '{0}/_apis/OrganizationPolicy/Policies/{1}?api-version={2}' -f $ApiUri.TrimEnd('/'), $PolicyName, $ApiVersion
        Method = 'GET'
    }
    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[Get-DevOpsOrganizationPolicy] Failed to retrieve organization policy '$PolicyName': $_" }
}
