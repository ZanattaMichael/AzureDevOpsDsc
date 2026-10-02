<#
.SYNOPSIS
Normalizes wiki page Markdown content for comparison.

.DESCRIPTION
The Wiki Pages API can return content with different line endings and trailing whitespace than
what was written (Windows-hosted wikis frequently round-trip CRLF, and editors and diffing tools
commonly strip trailing whitespace). Comparing the raw strings reports drift on every Test(), even
when nothing meaningful changed.

This helper normalizes only line endings and trailing whitespace:

- CRLF and lone CR line endings collapse to LF
- Trailing whitespace on each line is removed
- A single trailing newline at the end of the document is ignored

This is a comparison aid only. Never write the normalized form back to the API - store exactly
what the configuration supplied.

.PARAMETER Content
The Markdown content to normalize.

.EXAMPLE
ConvertTo-NormalizedWikiPageContent -Content "# Title `r`n`r`nBody text `r`n"
Returns "# Title`n`nBody text".
#>
Function ConvertTo-NormalizedWikiPageContent
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [AllowNull()]
        [String]$Content
    )

    Process
    {
        if ([String]::IsNullOrEmpty($Content))
        {
            return ''
        }

        # Collapse every line ending style to LF.
        $normalized = $Content -replace "`r`n", "`n" -replace "`r", "`n"

        # Strip trailing whitespace from each line without touching leading whitespace, which is
        # significant in Markdown (list nesting, code blocks).
        $lines = $normalized -split "`n" | ForEach-Object { $_ -replace '\s+$', '' }

        $normalized = ($lines -join "`n").TrimEnd("`n")

        return $normalized
    }
}
