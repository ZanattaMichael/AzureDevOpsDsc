<#
.SYNOPSIS
Normalizes a WIQL statement so that stored and returned forms can be compared.

.DESCRIPTION
The Queries API does not return the WIQL it was given. It returns a normalized form:
re-indented, re-wrapped, with keywords cased its own way and with a trailing semicolon that
may or may not have been supplied. Comparing the returned WIQL to the WIQL in a DSC
configuration as plain strings therefore reports drift on every single Test(), forever, even
when nothing has changed.

This helper reduces both sides to a comparable form:

- line breaks and runs of whitespace collapse to a single space
- whitespace around commas, brackets and operators is made consistent
- a trailing semicolon is removed
- WIQL keywords are upper-cased

Field names in square brackets and string literals in single quotes are left alone, since
those are case-sensitive to the user's intent even where WIQL itself tolerates differences.

This is a comparison aid only. Never write the normalized form back to the API - store what
the user supplied.

.PARAMETER Wiql
The WIQL statement to normalize.

.EXAMPLE
ConvertTo-NormalizedWiql -Wiql "select [System.Id]`n  from WorkItems where [System.State] = 'Active';"
Returns "SELECT [System.Id] FROM WorkItems WHERE [System.State] = 'Active'".
#>
Function ConvertTo-NormalizedWiql
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [AllowNull()]
        [String]$Wiql
    )

    Process
    {
        if ([String]::IsNullOrWhiteSpace($Wiql))
        {
            return ''
        }

        $normalized = $Wiql

        # Collapse all whitespace (including newlines and tabs) to single spaces.
        $normalized = $normalized -replace '\s+', ' '
        $normalized = $normalized.Trim()

        # A trailing semicolon is optional on input and inconsistent on output.
        $normalized = $normalized.TrimEnd(';').Trim()

        # Make spacing around separators and operators consistent.
        $normalized = $normalized -replace '\s*,\s*', ', '
        $normalized = $normalized -replace '\s*=\s*', ' = '
        $normalized = $normalized -replace '\s*<>\s*', ' <> '
        $normalized = $normalized -replace '\s*\[\s*', ' ['
        $normalized = $normalized -replace '\s*\]\s*', '] '
        $normalized = $normalized -replace '\s*\(\s*', ' ('
        $normalized = $normalized -replace '\s*\)\s*', ') '

        # Upper-case the WIQL keywords. Applied on word boundaries so that a field or literal
        # containing a keyword as a substring is left untouched.
        $keywords = @(
            'SELECT', 'FROM', 'WHERE', 'ORDER BY', 'GROUP BY', 'ASOF',
            'AND', 'OR', 'NOT', 'EVER', 'CONTAINS', 'WORDS', 'IN', 'UNDER',
            'ASC', 'DESC', 'MODE', 'RECURSIVE', 'MATCHING', 'WORKITEMS', 'WORKITEMLINKS'
        )

        foreach ($keyword in $keywords)
        {
            $pattern = '(?i)(?<![\w\[''])' + [Regex]::Escape($keyword) + '(?![\w\]''])'
            $normalized = [Regex]::Replace($normalized, $pattern, $keyword)
        }

        # The substitutions above can reintroduce doubled spaces.
        $normalized = ($normalized -replace '\s+', ' ').Trim()

        return $normalized
    }
}
