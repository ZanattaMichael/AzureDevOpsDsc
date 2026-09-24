<#
.SYNOPSIS
Writes one Azure DevOps organization policy.

.DESCRIPTION
PATCHes `_apis/OrganizationPolicy/Policies/{policyName}` with a JSON-patch document replacing the
policy's `/Value` (and, when supplied, its `/Url` — used only by the request-access policy). The
body is `application/json-patch+json`, matching what the *Organization settings -> Policies* page
sends.

.PARAMETER ApiUri
The base organization URI, e.g. 'https://dev.azure.com/myorg/'.

.PARAMETER PolicyName
The organization policy name, e.g. 'Policy.LogAuditEvents'.

.PARAMETER Value
The boolean value to write.

.PARAMETER Url
Optional companion URL to write alongside the policy value (request-access policy only).

.PARAMETER ApiVersion
The REST API version to use. Defaults to '5.0-preview.1'.

.EXAMPLE
Set-DevOpsOrganizationPolicy -ApiUri 'https://dev.azure.com/myorg/' -PolicyName 'Policy.LogAuditEvents' -Value $true
#>
function Set-DevOpsOrganizationPolicy
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory)][string]$ApiUri,
        [Parameter(Mandatory)][string]$PolicyName,
        [Parameter(Mandatory)][bool]$Value,
        [Parameter()][string]$Url,
        [Parameter()][string]$ApiVersion = '5.0-preview.1'
    )

    $patch = [System.Collections.ArrayList]::new()
    $null = $patch.Add(@{ from = ''; op = 2; path = '/Value'; value = $Value.ToString().ToLower() })
    if ($PSBoundParameters.ContainsKey('Url'))
    {
        $null = $patch.Add(@{ from = ''; op = 2; path = '/Url'; value = $Url })
    }

    $params = @{
        Uri         = '{0}/_apis/OrganizationPolicy/Policies/{1}?api-version={2}' -f $ApiUri.TrimEnd('/'), $PolicyName, $ApiVersion
        Method      = 'PATCH'
        ContentType = 'application/json-patch+json'
        Body        = $patch | ConvertTo-Json -Depth 10
    }

    if (-not $PSCmdlet.ShouldProcess($PolicyName, 'Update organization policy'))
    {
        return
    }

    try   { return Invoke-AzDevOpsApiRestMethod @params }
    catch { Throw "[Set-DevOpsOrganizationPolicy] Failed to update organization policy '$PolicyName': $_" }
}
