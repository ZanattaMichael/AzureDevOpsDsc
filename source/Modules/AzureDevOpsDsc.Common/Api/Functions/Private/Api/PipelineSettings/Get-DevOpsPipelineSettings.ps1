<#
.SYNOPSIS
Gets the pipeline general settings for an Azure DevOps project.

.DESCRIPTION
Retrieves the project's pipeline general settings via the Build REST API
(GET https://dev.azure.com/{org}/{project}/_apis/build/generalsettings). The response is a flat object
of boolean settings (enforceJobAuthScope, statusBadgesArePrivate, etc.).

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProjectName
The name (or id) of the project.

.PARAMETER ApiVersion
The REST API version to use. Defaults to '7.1'.

.OUTPUTS
The pipeline general settings object, or $null.

.EXAMPLE
Get-DevOpsPipelineSettings -Organization 'myorg' -ProjectName 'MyProject'
#>
function Get-DevOpsPipelineSettings
{
    [CmdletBinding()]
    [OutputType([System.Object])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$Organization,

        [Parameter(Mandatory = $true)]
        [string]$ProjectName,

        [Parameter()]
        [string]$ApiVersion = '7.1'
    )

    $params = @{
        Uri    = 'https://dev.azure.com/{0}/{1}/_apis/build/generalsettings?api-version={2}' -f $Organization, $ProjectName, $ApiVersion
        Method = 'Get'
    }

    try
    {
        return Invoke-AzDevOpsApiRestMethod @params
    }
    catch
    {
        Write-Verbose "[Get-DevOpsPipelineSettings] Lookup of pipeline settings for '$ProjectName' failed: $_"
        return $null
    }
}
