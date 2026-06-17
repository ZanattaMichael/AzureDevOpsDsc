<#
.SYNOPSIS
Resolves an Azure DevOps project by name from the cache, falling back to a live API lookup.

.DESCRIPTION
DSC resource New/Set/Remove functions need the parent project's id to call the REST API. The
project cache is built once at module init, so a project created later in the same configuration
(or by a test's setup) is not present. This helper returns the cached project when available and
otherwise performs a live lookup, caching the result. Returns $null when the project does not exist.

.PARAMETER ProjectName
The name of the Azure DevOps project to resolve.

.EXAMPLE
$project = Resolve-AzDoProject -ProjectName 'MyProject'
#>
function Resolve-AzDoProject
{
    [CmdletBinding()]
    [OutputType([Object])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ProjectName
    )

    $project = Get-CacheItem -Key $ProjectName -Type 'LiveProjects'
    if ($project)
    {
        return $project
    }

    Write-Verbose "[Resolve-AzDoProject] Project '$ProjectName' not in cache — falling back to live API lookup."
    $orgName = Get-AzDoOrganizationName
    try
    {
        $project = Invoke-AzDevOpsApiRestMethod -Uri "https://dev.azure.com/$orgName/_apis/projects/${ProjectName}?api-version=7.1-preview.4" -Method Get
    }
    catch
    {
        if ($_ -notmatch '404') { throw }
        $project = $null
    }

    if ($project)
    {
        Add-CacheItem -Key $ProjectName -Value $project -Type 'LiveProjects'
    }

    return $project
}
