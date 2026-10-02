<#
.SYNOPSIS
Retrieves the current state of an Azure DevOps wiki page.

.DESCRIPTION
Looks the page up live and compares its content and order against the desired state. Content is
compared with line-ending and trailing-whitespace differences ignored only - what gets written is
always exactly what the configuration supplied.

A missing project, missing wiki or missing page are all reported the same way: status NotFound.
Refusals the configuration itself causes - Content and ContentPath both supplied, a ContentPath
that does not exist, or a wiki that turns out to be a code wiki - are reported as status Error with
a 'reason', which Set/New/Remove must check for themselves: a Get status of Error still routes to
Set (see CLAUDE.md), so the refusal has to be repeated there or it will not hold.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER WikiName
The name of the wiki that contains this page.

.PARAMETER Path
The full path of the wiki page, for example '/Runbooks/On-call'.

.PARAMETER Content
The page's desired Markdown content. Mutually exclusive with ContentPath.

.PARAMETER ContentPath
A local file to read the page's Markdown content from. Mutually exclusive with Content.

.PARAMETER Order
The page's desired position among its sibling pages. Unspecified (sentinel -1), the page's order
is never compared.

.PARAMETER AllowRecursiveDelete
Permit deletion of a page that still has sub-pages.

.PARAMETER LookupResult
The lookup result supplied by the DSC base class.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.

.EXAMPLE
Get-AzDoWikiPage -ProjectName 'Contoso' -WikiName 'Contoso.wiki' -Path '/Runbooks/On-call'
#>
Function Get-AzDoWikiPage
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

    Write-Verbose "[Get-AzDoWikiPage] Started."

    $normalizedPath = Format-AzDoWikiPagePath -Path $Path

    $result = @{
        Ensure            = [Ensure]::Absent
        propertiesChanged = @()
        status            = $null
        reason            = $null
        path              = $normalizedPath
    }

    $hasContent     = -not [String]::IsNullOrEmpty($Content)
    $hasContentPath = -not [String]::IsNullOrWhiteSpace($ContentPath)

    if ($hasContent -and $hasContentPath)
    {
        Write-Error "[Get-AzDoWikiPage] Wiki page '$normalizedPath' in project '$ProjectName' supplies both Content and ContentPath. They are mutually exclusive; supply only one."
        $result.status = [DSCGetSummaryState]::Error
        $result.reason  = 'ContentAndContentPathBothSupplied'
        return $result
    }

    if ($hasContentPath -and -not (Test-Path -LiteralPath $ContentPath -PathType Leaf))
    {
        Write-Error "[Get-AzDoWikiPage] ContentPath '$ContentPath' for wiki page '$normalizedPath' in project '$ProjectName' does not exist."
        $result.status = [DSCGetSummaryState]::Error
        $result.reason  = 'ContentPathNotFound'
        return $result
    }

    $desiredContent = $null
    if ($hasContentPath)
    {
        $desiredContent = Get-Content -LiteralPath $ContentPath -Raw
    }
    elseif ($hasContent)
    {
        $desiredContent = $Content
    }

    $organization = Get-AzDoOrganizationName

    $project = Resolve-AzDoProject -ProjectName $ProjectName
    if ($null -eq $project)
    {
        Write-Verbose "[Get-AzDoWikiPage] Project '$ProjectName' does not exist."
        $result.status = [DSCGetSummaryState]::NotFound
        return $result
    }

    $wiki = Resolve-AzDoWiki -ProjectName $ProjectName -WikiName $WikiName
    if ($null -eq $wiki)
    {
        Write-Verbose "[Get-AzDoWikiPage] Wiki '$WikiName' does not exist in project '$ProjectName'."
        $result.status = [DSCGetSummaryState]::NotFound
        return $result
    }

    if ("$($wiki.type)" -eq 'codeWiki')
    {
        Write-Error "[Get-AzDoWikiPage] Wiki '$WikiName' in project '$ProjectName' is a code wiki: its pages are the content of a Git branch, so writing to one is a commit, not a configuration change. This resource only manages pages in a project wiki."
        $result.status = [DSCGetSummaryState]::Error
        $result.reason  = 'CodeWikiNotSupported'
        return $result
    }

    $wikiIdentifier = if ($wiki.id) { $wiki.id } else { $wiki.name }

    $lookup = Get-DevOpsWikiPage -Organization $organization -ProjectName $ProjectName -WikiIdentifier $wikiIdentifier `
        -Path $normalizedPath -IncludeContent -RecursionLevel 'OneLevel'

    if ($null -eq $lookup -or $null -eq $lookup.Page)
    {
        Write-Verbose "[Get-AzDoWikiPage] Wiki page '$normalizedPath' does not exist in wiki '$WikiName'."
        $result.status = [DSCGetSummaryState]::NotFound
        return $result
    }

    $result.liveCache      = $lookup.Page
    $result.wikiIdentifier = $wikiIdentifier
    $result.Ensure         = [Ensure]::Present

    $propertiesChanged = @()

    if ($null -ne $desiredContent)
    {
        $normalizedCurrent = ConvertTo-NormalizedWikiPageContent -Content $lookup.Page.content
        $normalizedDesired = ConvertTo-NormalizedWikiPageContent -Content $desiredContent

        if ($normalizedCurrent -ne $normalizedDesired)
        {
            Write-Verbose "[Get-AzDoWikiPage] Content differs for wiki page '$normalizedPath'."
            $propertiesChanged += 'Content'
        }
    }

    if ($PSBoundParameters.ContainsKey('Order') -and $Order -ge 0)
    {
        if ([int]$lookup.Page.order -ne $Order)
        {
            Write-Verbose "[Get-AzDoWikiPage] Order differs for wiki page '$normalizedPath'."
            $propertiesChanged += 'Order'
        }
    }

    $result.propertiesChanged = $propertiesChanged
    $result.status = if ($propertiesChanged.Count -gt 0) { [DSCGetSummaryState]::Changed } else { [DSCGetSummaryState]::Unchanged }

    Write-Verbose "[Get-AzDoWikiPage] Wiki page '$normalizedPath' status: $($result.status)."

    return $result
}
