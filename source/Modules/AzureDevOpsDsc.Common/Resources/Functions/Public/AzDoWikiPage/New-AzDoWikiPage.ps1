<#
.SYNOPSIS
Creates an Azure DevOps wiki page.

.DESCRIPTION
Creates the page at the configured path with the configured content, then reorders it among its
siblings if Order was configured. The refusals Get-AzDoWikiPage decides on - Content and
ContentPath both supplied, a ContentPath that does not exist, or the wiki turning out to be a code
wiki - are re-checked here directly: a Get status of Error still routes to Set rather than New, but
New is reachable on its own (a first-time apply calls it directly, without a prior Get pass), so it
cannot rely on a refusal only ever being decided upstream.

.PARAMETER ProjectName
The name of the Azure DevOps project.

.PARAMETER WikiName
The name of the wiki that contains this page.

.PARAMETER Path
The full path of the wiki page.

.PARAMETER Content
The page's Markdown content. Mutually exclusive with ContentPath. Neither supplied creates an
empty page - a common way to stand up a parent page that exists only to organize pages beneath it.

.PARAMETER ContentPath
A local file to read the page's Markdown content from. Mutually exclusive with Content.

.PARAMETER Order
The page's desired position among its sibling pages. Unspecified (sentinel -1), the page is left
at whatever position the API assigns it.

.PARAMETER AllowRecursiveDelete
Permit deletion of a page that still has sub-pages. Unused by New; declared because the DSC base
class splats every resource property into every action function.

.PARAMETER LookupResult
The lookup result supplied by the DSC base class.

.PARAMETER Ensure
The desired state, supplied by the DSC base class.

.PARAMETER Force
Forces the operation, supplied by the DSC base class.

.EXAMPLE
New-AzDoWikiPage -ProjectName 'Contoso' -WikiName 'Contoso.wiki' -Path '/Runbooks/On-call' -Content '# On-call'
#>
Function New-AzDoWikiPage
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

    Write-Verbose "[New-AzDoWikiPage] Started."

    $normalizedPath = Format-AzDoWikiPagePath -Path $Path
    $organization   = Get-AzDoOrganizationName

    $hasContent     = -not [String]::IsNullOrEmpty($Content)
    $hasContentPath = -not [String]::IsNullOrWhiteSpace($ContentPath)

    if ($hasContent -and $hasContentPath)
    {
        throw "[New-AzDoWikiPage] Wiki page '$normalizedPath' in project '$ProjectName' supplies both Content and ContentPath. They are mutually exclusive; supply only one."
    }

    if ($hasContentPath -and -not (Test-Path -LiteralPath $ContentPath -PathType Leaf))
    {
        throw "[New-AzDoWikiPage] ContentPath '$ContentPath' for wiki page '$normalizedPath' in project '$ProjectName' does not exist."
    }

    $desiredContent = if ($hasContentPath) { Get-Content -LiteralPath $ContentPath -Raw } elseif ($hasContent) { $Content } else { '' }

    $project = Resolve-AzDoProject -ProjectName $ProjectName
    if ($null -eq $project)
    {
        throw "[New-AzDoWikiPage] Project '$ProjectName' does not exist. Cannot create wiki page '$normalizedPath'."
    }

    $wiki = Resolve-AzDoWiki -ProjectName $ProjectName -WikiName $WikiName
    if ($null -eq $wiki)
    {
        throw "[New-AzDoWikiPage] Wiki '$WikiName' does not exist in project '$ProjectName'. Cannot create wiki page '$normalizedPath'."
    }

    if ("$($wiki.type)" -eq 'codeWiki')
    {
        throw "[New-AzDoWikiPage] Wiki '$WikiName' in project '$ProjectName' is a code wiki: its pages are the content of a Git branch, so writing to one is a commit, not a configuration change. This resource only manages pages in a project wiki."
    }

    $wikiIdentifier = if ($wiki.id) { $wiki.id } else { $wiki.name }

    Write-Verbose "[New-AzDoWikiPage] Creating wiki page '$normalizedPath' in wiki '$WikiName'."

    try
    {
        $created = Set-DevOpsWikiPage -Organization $organization -ProjectName $ProjectName -WikiIdentifier $wikiIdentifier `
            -Path $normalizedPath -Content $desiredContent
    }
    catch
    {
        # The API does not create parent pages. Name the missing parent and the fix, rather than
        # passing on the API's "one or more ancestor pages ... does not exist".
        if ("$_" -match 'WikiAncestorPageNotFoundException')
        {
            $parentPath = $normalizedPath.Substring(0, $normalizedPath.LastIndexOf('/'))
            throw "[New-AzDoWikiPage] Cannot create wiki page '$normalizedPath' in wiki '$WikiName': its parent page '$parentPath' does not exist, and the wiki API does not create parent pages. Declare '$parentPath' as its own AzDoWikiPage (Content can be omitted) and make this resource depend on it."
        }
        throw
    }

    if ($null -eq $created)
    {
        throw "[New-AzDoWikiPage] Failed to create wiki page '$normalizedPath' in wiki '$WikiName'. The API returned no result."
    }

    if ($PSBoundParameters.ContainsKey('Order') -and $Order -ge 0)
    {
        try
        {
            $null = Move-DevOpsWikiPage -Organization $organization -ProjectName $ProjectName -WikiIdentifier $wikiIdentifier `
                -Path $normalizedPath -NewOrder $Order
        }
        catch
        {
            # The page itself was created successfully - only the ordering failed. Throwing here
            # still marks the DSC application as failed (correctly - the desired state was not
            # fully reached), but the message should not read as though nothing happened.
            throw "[New-AzDoWikiPage] Wiki page '$normalizedPath' was created, but could not be moved to order $Order. Error: $_"
        }
    }

    return $created
}
