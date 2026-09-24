<#
.SYNOPSIS
Updates an Azure DevOps wiki page.

.DESCRIPTION
Re-reads the page immediately before writing it, so the ETag sent back as 'If-Match' is the page's
current version rather than one that may have gone stale during the wait between Get and Set. A
stale ETag is rejected with 412; Set-DevOpsWikiPage surfaces that as a clear error rather than a
raw HTTP status.

Content is only rewritten when it actually differs (normalized for line endings and trailing
whitespace only) - leaving Content and ContentPath both unspecified, or unchanged, updates the
page's order alone without touching its content. Order is only compared, and only moved, when it
was actually configured; Order left unspecified never triggers a page move.

The refusals Get-AzDoWikiPage decides on are re-checked here directly, because a Get status of
Error still routes to Set (see CLAUDE.md) and Set can also be reached without a prior Get in a
direct call.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER WikiName
The name of the wiki that contains this page.

.PARAMETER Path
The full path of the wiki page.

.PARAMETER Content
The page's desired Markdown content. Mutually exclusive with ContentPath.

.PARAMETER ContentPath
A local file to read the page's Markdown content from. Mutually exclusive with Content.

.PARAMETER Order
The page's desired position among its sibling pages. Unspecified (sentinel -1), the page's order
is left alone.

.PARAMETER AllowRecursiveDelete
Permit deletion of a page that still has sub-pages. Unused by Set; declared because the DSC base
class splats every resource property into every action function.

.PARAMETER LookupResult
The lookup result supplied by the DSC base class.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.

.EXAMPLE
Set-AzDoWikiPage -ProjectName 'Contoso' -WikiName 'Contoso.wiki' -Path '/Runbooks/On-call' -Content '# On-call (updated)'
#>
Function Set-AzDoWikiPage
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

    Write-Verbose "[Set-AzDoWikiPage] Started."

    $normalizedPath = Format-AzDoWikiPagePath -Path $Path
    $organization   = Get-AzDoOrganizationName

    $hasContent     = -not [String]::IsNullOrEmpty($Content)
    $hasContentPath = -not [String]::IsNullOrWhiteSpace($ContentPath)

    if ($hasContent -and $hasContentPath)
    {
        throw "[Set-AzDoWikiPage] Wiki page '$normalizedPath' in project '$ProjectName' supplies both Content and ContentPath. They are mutually exclusive; supply only one."
    }

    if ($hasContentPath -and -not (Test-Path -LiteralPath $ContentPath -PathType Leaf))
    {
        throw "[Set-AzDoWikiPage] ContentPath '$ContentPath' for wiki page '$normalizedPath' in project '$ProjectName' does not exist."
    }

    # $null means neither was specified - leave the page's content alone.
    $desiredContent = if ($hasContentPath) { Get-Content -LiteralPath $ContentPath -Raw } elseif ($hasContent) { $Content } else { $null }

    $project = Resolve-AzDoProject -ProjectName $ProjectName
    if ($null -eq $project)
    {
        throw "[Set-AzDoWikiPage] Project '$ProjectName' does not exist. Cannot update wiki page '$normalizedPath'."
    }

    $wiki = Resolve-AzDoWiki -ProjectName $ProjectName -WikiName $WikiName
    if ($null -eq $wiki)
    {
        throw "[Set-AzDoWikiPage] Wiki '$WikiName' does not exist in project '$ProjectName'. Cannot update wiki page '$normalizedPath'."
    }

    if ("$($wiki.type)" -eq 'codeWiki')
    {
        throw "[Set-AzDoWikiPage] Wiki '$WikiName' in project '$ProjectName' is a code wiki: its pages are the content of a Git branch, so writing to one is a commit, not a configuration change. This resource only manages pages in a project wiki."
    }

    $wikiIdentifier = if ($wiki.id) { $wiki.id } else { $wiki.name }

    # Read the page fresh, inside this same Set, so the ETag used as If-Match is the page's
    # current version rather than one read earlier that may since have gone stale.
    $lookup = Get-DevOpsWikiPage -Organization $organization -ProjectName $ProjectName -WikiIdentifier $wikiIdentifier -Path $normalizedPath -IncludeContent

    if ($null -eq $lookup -or $null -eq $lookup.Page)
    {
        throw "[Set-AzDoWikiPage] Wiki page '$normalizedPath' in wiki '$WikiName' no longer exists. Cannot update it."
    }

    $contentUpdated = $false

    if ($null -ne $desiredContent)
    {
        $normalizedCurrent = ConvertTo-NormalizedWikiPageContent -Content $lookup.Page.content
        $normalizedDesired = ConvertTo-NormalizedWikiPageContent -Content $desiredContent

        if ($normalizedCurrent -ne $normalizedDesired)
        {
            Write-Verbose "[Set-AzDoWikiPage] Updating content for wiki page '$normalizedPath'."
            $null = Set-DevOpsWikiPage -Organization $organization -ProjectName $ProjectName -WikiIdentifier $wikiIdentifier `
                -Path $normalizedPath -Content $desiredContent -ETag $lookup.ETag
            $contentUpdated = $true
        }
        else
        {
            Write-Verbose "[Set-AzDoWikiPage] Content for wiki page '$normalizedPath' already matches the desired state."
        }
    }

    if ($PSBoundParameters.ContainsKey('Order') -and $Order -ge 0 -and [int]$lookup.Page.order -ne $Order)
    {
        Write-Verbose "[Set-AzDoWikiPage] Moving wiki page '$normalizedPath' to order $Order."

        try
        {
            $null = Move-DevOpsWikiPage -Organization $organization -ProjectName $ProjectName -WikiIdentifier $wikiIdentifier `
                -Path $normalizedPath -NewOrder $Order
        }
        catch
        {
            if ($contentUpdated)
            {
                throw "[Set-AzDoWikiPage] Wiki page '$normalizedPath' had its content updated, but could not be moved to order $Order. Error: $_"
            }

            throw "[Set-AzDoWikiPage] Wiki page '$normalizedPath' could not be moved to order $Order. Error: $_"
        }
    }
}
