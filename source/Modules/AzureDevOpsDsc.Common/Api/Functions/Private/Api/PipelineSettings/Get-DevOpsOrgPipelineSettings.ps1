<#
.SYNOPSIS
Gets the organization-scoped pipeline general settings for an Azure DevOps organization.

.DESCRIPTION
Retrieves the organization's pipeline general settings via the Build REST API
(GET https://dev.azure.com/{org}/_apis/build/generalsettings), the same resource as
Get-DevOpsPipelineSettings but without a project segment. The response is a flat object of boolean
settings (enforceJobAuthScope, statusBadgesArePrivate, etc.) that applies org-wide.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ApiVersion
The REST API version to use. Defaults to '7.1'.

.OUTPUTS
The organization pipeline general settings object, or $null.

.EXAMPLE
Get-DevOpsOrgPipelineSettings -Organization 'myorg'
#>
function Get-DevOpsOrgPipelineSettings
{
    [CmdletBinding()]
    [OutputType([System.Object])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$Organization,

        [Parameter()]
        [string]$ApiVersion = '7.1'
    )

    $params = @{
        Uri    = 'https://dev.azure.com/{0}/_apis/build/generalsettings?api-version={1}' -f $Organization, $ApiVersion
        Method = 'Get'
    }

    try
    {
        return Invoke-AzDevOpsApiRestMethod @params
    }
    catch
    {
        Write-Verbose "[Get-DevOpsOrgPipelineSettings] Lookup of organization pipeline settings for '$Organization' failed: $_"
        return $null
    }
}
