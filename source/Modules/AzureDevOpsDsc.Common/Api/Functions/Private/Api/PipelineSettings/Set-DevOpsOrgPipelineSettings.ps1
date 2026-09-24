<#
.SYNOPSIS
Updates the organization-scoped pipeline general settings for an Azure DevOps organization.

.DESCRIPTION
Patches the organization's pipeline general settings via the Build REST API
(PATCH https://dev.azure.com/{org}/_apis/build/generalsettings), the same resource as
Set-DevOpsPipelineSettings but without a project segment. Only the supplied keys are changed; the
endpoint merges them with the existing settings.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER Settings
A hashtable of the settings to change (API field names mapped to boolean values).

.PARAMETER ApiVersion
The REST API version to use. Defaults to '7.1'.

.EXAMPLE
Set-DevOpsOrgPipelineSettings -Organization 'myorg' -Settings @{ enforceJobAuthScope = $true }
#>
function Set-DevOpsOrgPipelineSettings
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$Organization,

        [Parameter(Mandatory = $true)]
        [hashtable]$Settings,

        [Parameter()]
        [string]$ApiVersion = '7.1'
    )

    if ($Settings.Count -eq 0)
    {
        Write-Verbose '[Set-DevOpsOrgPipelineSettings] No settings supplied; nothing to do.'
        return
    }

    $params = @{
        Uri    = 'https://dev.azure.com/{0}/_apis/build/generalsettings?api-version={1}' -f $Organization, $ApiVersion
        Method = 'PATCH'
        Body   = $Settings | ConvertTo-Json -Depth 4
    }

    if (-not $PSCmdlet.ShouldProcess($Organization, 'Update organization pipeline general settings'))
    {
        return
    }

    try
    {
        return Invoke-AzDevOpsApiRestMethod @params
    }
    catch
    {
        throw "[Set-DevOpsOrgPipelineSettings] Failed to update organization pipeline settings for '$Organization': $_"
    }
}
