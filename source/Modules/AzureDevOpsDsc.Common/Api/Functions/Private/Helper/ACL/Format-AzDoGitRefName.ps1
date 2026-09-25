<#
.SYNOPSIS
Normalizes a Git branch or tag name into its bare ref-name form for comparison.

.DESCRIPTION
Users may write a branch or tag name either bare ('main', 'release/1.0') or fully qualified
('refs/heads/main', 'refs/tags/release/1.0'), copied from a URL or 'git branch -a' output. Both
spellings mean the same ref, so comparing them raw would report drift on every Test(). This strips
an optional, case-insensitive leading 'refs/heads/' or 'refs/tags/' and trims a trailing '/', but -
per the "compare normalized, store what the user wrote" convention - only for comparison; the value
written back to the API and to the resource's current state is always the name as the configuration
supplied it, never this normalized form.

.PARAMETER RefName
The branch or tag name to normalize, bare or fully qualified.

.EXAMPLE
Format-AzDoGitRefName -RefName 'refs/heads/main'
Returns 'main'.

.EXAMPLE
Format-AzDoGitRefName -RefName 'release/1.0'
Returns 'release/1.0'.
#>
Function Format-AzDoGitRefName
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [String]$RefName
    )

    Process
    {
        if ([String]::IsNullOrWhiteSpace($RefName))
        {
            return ''
        }

        $normalized = $RefName -replace '^\s*refs/(heads|tags)/', ''
        $normalized = $normalized.Trim().Trim('/')

        return $normalized
    }
}
