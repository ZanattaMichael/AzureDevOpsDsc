<#
.SYNOPSIS
Removes an Azure DevOps wiki page.

.DESCRIPTION
Deletes the page. Deleting a wiki page deletes every sub-page beneath it, so a page that still has
sub-pages is left alone unless AllowRecursiveDelete is set. Without that guard, narrowing a
configuration to remove one page would take an arbitrary number of other pages with it.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER WikiName
The name of the wiki that contains this page.

.PARAMETER Path
The full path of the wiki page.

.PARAMETER Content
The page's Markdown content. Unused by Remove; declared because the DSC base class splats every
resource property into every action function.

.PARAMETER ContentPath
A local file the page's content would be read from. Unused by Remove.

.PARAMETER Order
The page's desired position among its sibling pages. Unused by Remove.

.PARAMETER AllowRecursiveDelete
Permit deletion of a page that still has sub-pages.

.PARAMETER LookupResult
The lookup result supplied by the DSC base class. Its 'liveCache' - the page Get already fetched
with one level of sub-pages populated - is reused here to avoid a second lookup.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.

.EXAMPLE
Remove-AzDoWikiPage -ProjectName 'Contoso' -WikiName 'Contoso.wiki' -Path '/Runbooks/On-call' -AllowRecursiveDelete $true
#>
Function Remove-AzDoWikiPage
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [Alias('Name')]
        [System.String]$ProjectName,

        [Parameter(Mandatory = $true)]
        [System.String]$WikiName,

        [Parameter(Mandatory = $true)]
        [System.String]$Path,

        [Parameter()]
        [AllowEmptyString()]
        [System.String]$Content,

        [Parameter()]
        [AllowEmptyString()]
        [System.String]$ContentPath,

        [Parameter()]
        [System.Int32]$Order,

        [Parameter()]
        [System.Boolean]$AllowRecursiveDelete,

        [Parameter()]
        [HashTable]$LookupResult,

        [Parameter()]
        [Ensure]$Ensure,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]$Force
    )

    Write-Verbose "[Remove-AzDoWikiPage] Started."

    $normalizedPath = Format-AzDoWikiPagePath -Path $Path
    $organization   = Get-AzDoOrganizationName

    $project = Resolve-AzDoProject -ProjectName $ProjectName
    if ($null -eq $project)
    {
        Write-Verbose "[Remove-AzDoWikiPage] Project '$ProjectName' does not exist. Nothing to remove."
        return
    }

    $wiki = Resolve-AzDoWiki -ProjectName $ProjectName -WikiName $WikiName
    if ($null -eq $wiki)
    {
        Write-Verbose "[Remove-AzDoWikiPage] Wiki '$WikiName' does not exist in project '$ProjectName'. Nothing to remove."
        return
    }

    if ("$($wiki.type)" -eq 'codeWiki')
    {
        throw "[Remove-AzDoWikiPage] Wiki '$WikiName' in project '$ProjectName' is a code wiki: its pages are the content of a Git branch, so deleting one is a commit, not a configuration change. This resource only manages pages in a project wiki."
    }

    $wikiIdentifier = if ($wiki.id) { $wiki.id } else { $wiki.name }

    # Prefer the page Get already retrieved with one level of sub-pages populated; fall back to a
    # fresh lookup when called outside the DSC pipeline.
    $page = $LookupResult.liveCache

    if ($null -eq $page)
    {
        $lookup = Get-DevOpsWikiPage -Organization $organization -ProjectName $ProjectName -WikiIdentifier $wikiIdentifier `
            -Path $normalizedPath -RecursionLevel 'OneLevel'
        $page   = $lookup.Page
    }

    if ($null -eq $page)
    {
        Write-Verbose "[Remove-AzDoWikiPage] Wiki page '$normalizedPath' does not exist. Nothing to remove."
        return
    }

    $hasSubPages = (@($page.subPages) | Where-Object { $null -ne $_ }).Count -gt 0

    if ($hasSubPages -and (-not $AllowRecursiveDelete))
    {
        throw "[Remove-AzDoWikiPage] Wiki page '$normalizedPath' in wiki '$WikiName' has sub-pages. Deleting it would delete every sub-page beneath it. Set AllowRecursiveDelete = `$true to permit this."
    }

    if ($hasSubPages)
    {
        Write-Warning "[Remove-AzDoWikiPage] Recursively deleting wiki page '$normalizedPath' and every sub-page beneath it."
    }

    Write-Verbose "[Remove-AzDoWikiPage] Removing wiki page '$normalizedPath'."

    return (Remove-DevOpsWikiPage -Organization $organization -ProjectName $ProjectName -WikiIdentifier $wikiIdentifier -Path $normalizedPath)
}
