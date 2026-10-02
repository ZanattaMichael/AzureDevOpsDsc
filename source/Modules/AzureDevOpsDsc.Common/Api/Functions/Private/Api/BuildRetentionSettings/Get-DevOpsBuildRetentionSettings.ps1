<#
.SYNOPSIS
Gets the build (run/artifact) retention settings for an Azure DevOps project.

.DESCRIPTION
Retrieves the project's retention settings via the Build REST API
(GET https://dev.azure.com/{org}/{project}/_apis/build/retention). The response is an object with one
key per setting (purgeRuns, purgeArtifacts, purgePullRequestRuns, retainRunsPerProtectedBranch), each
carrying the current 'value' plus the org's own 'min'/'max' bounds for it.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProjectName
The name (or id) of the project.

.PARAMETER ApiVersion
The REST API version to use. Defaults to '7.1'.

.OUTPUTS
The retention settings object, or $null.

.EXAMPLE
Get-DevOpsBuildRetentionSettings -Organization 'myorg' -ProjectName 'MyProject'
#>
function Get-DevOpsBuildRetentionSettings
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
        Uri    = 'https://dev.azure.com/{0}/{1}/_apis/build/retention?api-version={2}' -f $Organization, $ProjectName, $ApiVersion
        Method = 'Get'
    }

    try
    {
        return Invoke-AzDevOpsApiRestMethod @params
    }
    catch
    {
        Write-Verbose "[Get-DevOpsBuildRetentionSettings] Lookup of retention settings for '$ProjectName' failed: $_"
        return $null
    }
}
