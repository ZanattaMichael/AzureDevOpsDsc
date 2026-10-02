<#
.SYNOPSIS
Gets an Azure DevOps project's capabilities, including its current process.

.DESCRIPTION
The plain project list/get endpoints (used to seed the LiveProjects cache) do not report which
process a project is on. This calls _apis/projects/{id} with includeCapabilities=true, which adds
a capabilities.processTemplate.templateTypeId/templateName block to the response.

.PARAMETER Organization
The name of the Azure DevOps organization.

.PARAMETER ProjectId
The id or name of the project.

.PARAMETER ApiVersion
The REST API version to use. Defaults to '7.1'.

.OUTPUTS
The project object with its capabilities property populated, or $null if the lookup failed.

.EXAMPLE
Get-DevOpsProjectCapabilities -Organization 'myorg' -ProjectId '11111111-1111-1111-1111-111111111111'
#>
function Get-DevOpsProjectCapabilities
{
    [CmdletBinding()]
    [OutputType([System.Object])]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$Organization,

        [Parameter(Mandatory = $true)]
        [string]$ProjectId,

        [Parameter()]
        [string]$ApiVersion = '7.1'
    )

    $params = @{
        Uri    = 'https://dev.azure.com/{0}/_apis/projects/{1}?includeCapabilities=true&api-version={2}' -f $Organization, $ProjectId, $ApiVersion
        Method = 'Get'
    }

    try
    {
        return Invoke-AzDevOpsApiRestMethod @params
    }
    catch
    {
        Write-Verbose "[Get-DevOpsProjectCapabilities] Lookup of project '$ProjectId' capabilities failed: $_"
        return $null
    }
}
