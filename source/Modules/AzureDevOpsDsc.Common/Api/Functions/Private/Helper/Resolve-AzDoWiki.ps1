<#
.SYNOPSIS
Resolves an Azure DevOps wiki by project and name.

.DESCRIPTION
Looks the wiki up in the 'LiveWikis' cache (built at module init from List-DevOpsWikis, the same
source Get-AzDoWiki uses), falling back to a live lookup and caching the result when the wiki was
created after the cache was built.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER WikiName
The name of the wiki.

.EXAMPLE
Resolve-AzDoWiki -ProjectName 'Contoso' -WikiName 'Contoso.wiki'
#>
Function Resolve-AzDoWiki
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]$ProjectName,

        [Parameter(Mandatory = $true)]
        [System.String]$WikiName
    )

    $cacheKey = '{0}\{1}' -f $ProjectName, $WikiName
    $wiki = Get-CacheItem -Key $cacheKey -Type 'LiveWikis'

    if ($wiki)
    {
        return $wiki
    }

    Write-Verbose "[Resolve-AzDoWiki] Wiki '$WikiName' not in cache — falling back to live API lookup."

    $orgName  = Get-AzDoOrganizationName
    $allWikis = List-DevOpsWikis -ApiUri "https://dev.azure.com/$orgName" -ProjectName $ProjectName
    $wiki     = $allWikis | Where-Object { $_.name -eq $WikiName } | Select-Object -First 1

    if ($wiki)
    {
        Add-CacheItem -Key $cacheKey -Value $wiki -Type 'LiveWikis'
    }

    return $wiki
}
