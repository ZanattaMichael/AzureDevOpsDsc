<#
.SYNOPSIS
Resolves an Azure DevOps service connection by name from the cache, falling back to a live API
lookup.

.DESCRIPTION
DSC resource New/Set/Get functions that reach a GitHub, GitHub Enterprise or Bitbucket repository
need the service connection's endpoint id to call the REST API. The service connection cache is
built once at module init, so a connection created later in the same configuration (or by a
test's setup) is not present. This helper returns the cached connection when available and
otherwise performs a live lookup, caching the result. Returns $null when the connection does not
exist.

.PARAMETER ProjectName
The name of the Azure DevOps project the service connection belongs to.

.PARAMETER ConnectionName
The name of the service connection to resolve.

.EXAMPLE
$connection = Resolve-AzDoServiceConnection -ProjectName 'MyProject' -ConnectionName 'GitHub-org'
#>
function Resolve-AzDoServiceConnection
{
    [CmdletBinding()]
    [OutputType([Object])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ProjectName,

        [Parameter(Mandatory = $true)]
        [string]$ConnectionName
    )

    $cacheKey = '{0}\{1}' -f $ProjectName, $ConnectionName
    $connection = Get-CacheItem -Key $cacheKey -Type 'LiveServiceConnections'

    if ($connection)
    {
        return $connection
    }

    Write-Verbose "[Resolve-AzDoServiceConnection] Service connection '$ConnectionName' not in cache — falling back to live API lookup."
    $orgName = Get-AzDoOrganizationName
    $allConnections = List-DevOpsServiceConnections -ApiUri "https://dev.azure.com/$orgName" -ProjectName $ProjectName
    $connection = $allConnections | Where-Object { $_.name -eq $ConnectionName } | Select-Object -First 1

    if ($connection)
    {
        Add-CacheItem -Key $cacheKey -Value $connection -Type 'LiveServiceConnections'
    }

    return $connection
}
