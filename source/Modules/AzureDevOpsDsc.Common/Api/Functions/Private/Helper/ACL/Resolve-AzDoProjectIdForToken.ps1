<#
.SYNOPSIS
Resolves a project's id for ACL token construction, falling back to a live lookup on cache miss.

.DESCRIPTION
New-ACLToken's Build/Library/ServiceEndpoints/DistributedTask/Git branches all resolve a project name
to its id via a plain 'LiveProjects' cache lookup with no live-API fallback. When the project is not
(yet) in cache, that silently produces a token with a $null ProjectId, which the ACL API accepts
without error but which never matches the intended project - the Set/Get then operate on a token that
resolves to nothing, so the resource never converges. This centralises the same
cache-then-live-fallback pattern already used elsewhere (e.g. Get-AzDoProject) for token construction.

.PARAMETER ProjectName
The name of the project to resolve.

.OUTPUTS
The project's id (string), or $null if the project genuinely does not exist.
#>
Function Resolve-AzDoProjectIdForToken
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectName
    )

    $project = Get-CacheItem -Key $ProjectName -Type 'LiveProjects'
    if ($project) { return $project.id }

    Write-Verbose "[Resolve-AzDoProjectIdForToken] Project '$ProjectName' not in cache — falling back to live API lookup."
    try
    {
        $OrganizationName = Get-AzDoOrganizationName
        $project = Invoke-AzDevOpsApiRestMethod -Uri "https://dev.azure.com/$OrganizationName/_apis/projects/${ProjectName}?api-version=7.1-preview.4" -Method Get
        if ($project) { Add-CacheItem -Key $ProjectName -Value $project -Type 'LiveProjects' -SuppressWarning }
    }
    catch
    {
        Write-Verbose "[Resolve-AzDoProjectIdForToken] Live lookup for project '$ProjectName' failed: $_"
        return $null
    }

    return $project.id
}
