<#
.SYNOPSIS
    DSC resource for managing the content and ordering of an Azure DevOps wiki page.

.DESCRIPTION
    Manages a single page within an existing project wiki: its Markdown content and its position
    among its sibling pages. AzDoWiki manages the wiki itself; this resource manages a page inside
    one.

    Only project wikis are supported. A code wiki's content lives in a Git branch, so writing a
    page there is a commit rather than a configuration change, and can conflict with an open pull
    request against that branch. Pointing this resource at a code wiki is refused.

.NOTES
    Author: Michael Zanatta

    Content and ContentPath are mutually exclusive - supplying both, or a ContentPath that does
    not exist on the node applying the configuration, is refused rather than guessed at.

    Content comparison ignores line-ending and trailing-whitespace differences only, since the
    API can round-trip content with different line endings than what was written. What gets
    written back is always exactly what the configuration supplied (CLAUDE.md gotcha 9).

    Updating a page needs its current ETag sent back as 'If-Match'; a stale one is rejected with
    412. That read-then-write happens inside Set(), so there is no gap for someone else's edit to
    land in between.

    Deleting a page deletes every sub-page beneath it. Removal of a page that still has sub-pages
    is refused unless AllowRecursiveDelete is set - this is the same pattern as AzDoQueryFolder and
    AzDoPipelineFolder, and deliberately not named 'Force', which is reserved by the base class.

.PARAMETER ProjectName
    The name of the Azure DevOps project.

.PARAMETER WikiName
    The name of the wiki that contains this page. Resolved via the 'LiveWikis' cache, the same way
    AzDoWiki resolves it. Only a project wiki (WikiType 'projectWiki') is supported.

.PARAMETER Path
    The full path of the wiki page, for example '/Runbooks/On-call'. This is the resource key.

.PARAMETER Content
    The page's Markdown content. Mutually exclusive with ContentPath.

.PARAMETER ContentPath
    A local file to read the page's Markdown content from. Keeps large pages out of the
    configuration itself. Mutually exclusive with Content.

.PARAMETER Order
    The page's desired position among its sibling pages. Left unspecified, the page's order is
    never compared or changed.

.PARAMETER AllowRecursiveDelete
    Deleting a wiki page deletes every sub-page beneath it. Removal of a page that still has
    sub-pages is refused unless this is set to $true.

.INPUTS
    None

.OUTPUTS
    None

.EXAMPLE
    AzDoWikiPage OnCallRunbook
    {
        ProjectName = 'Contoso'
        WikiName    = 'Contoso.wiki'
        Path        = '/Runbooks/On-call'
        Content     = '# On-call`n`nRun `Get-Incident` to see the current rotation.'
        Ensure      = 'Present'
    }
#>

[DscResource()]
class AzDoWikiPage : AzDevOpsDscResourceBase
{
    [DscProperty(Mandatory)]
    [Alias('Name')]
    [System.String]$ProjectName

    [DscProperty(Mandatory)]
    [System.String]$WikiName

    [DscProperty(Key, Mandatory)]
    [System.String]$Path

    [DscProperty()]
    [System.String]$Content

    [DscProperty()]
    [System.String]$ContentPath

    # -1 means "not configured" rather than "must be reordered to the first position" - a real
    # page order is never negative. Splatting through the DSC base class always supplies every
    # property, so this sentinel is the only reliable way to tell an unbound Order apart from one
    # explicitly set to 0.
    [DscProperty()]
    [System.Int32]$Order = -1

    [DscProperty()]
    [System.Boolean]$AllowRecursiveDelete = $false

    AzDoWikiPage()
    {
        $this.Construct()
    }

    [void] Set() { ([AzDevOpsDscResourceBase]$this).Set() }
    [System.Boolean] Test() { return ([AzDevOpsDscResourceBase]$this).Test() }
    [AzDoWikiPage] Get()
    {
        return [AzDoWikiPage]$($this.GetDscCurrentStateProperties())
    }

    hidden [System.String[]]GetDscResourcePropertyNamesWithNoSetSupport()
    {
        return @()
    }

    hidden [Hashtable]GetDscCurrentStateProperties([PSCustomObject]$CurrentResourceObject)
    {
        $properties = @{
            Ensure = [Ensure]::Absent
        }

        # If the resource object is null, return the properties
        if ($null -eq $CurrentResourceObject)
        {
            return $properties
        }

        $properties.ProjectName           = $CurrentResourceObject.ProjectName
        $properties.WikiName              = $CurrentResourceObject.WikiName
        $properties.Path                  = $CurrentResourceObject.Path
        $properties.Content               = $CurrentResourceObject.Content
        $properties.ContentPath           = $CurrentResourceObject.ContentPath
        $properties.Order                 = $CurrentResourceObject.Order
        $properties.AllowRecursiveDelete  = $CurrentResourceObject.AllowRecursiveDelete
        $properties.LookupResult          = $CurrentResourceObject.LookupResult
        $properties.Ensure                = $CurrentResourceObject.Ensure

        Write-Verbose "[AzDoWikiPage] Current state properties: $($properties | Out-String)"

        return $properties
    }
}
