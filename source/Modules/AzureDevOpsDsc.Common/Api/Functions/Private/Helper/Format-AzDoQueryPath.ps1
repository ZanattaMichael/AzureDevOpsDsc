<#
.SYNOPSIS
Normalizes a work item query path into the canonical form used by the Queries API.

.DESCRIPTION
Query paths are forward-slash delimited and rooted at 'Shared Queries' or 'My Queries'.
Users write them inconsistently - with backslashes copied from the Azure DevOps UI, with a
leading or trailing slash, or with doubled separators - and each spelling would otherwise
be treated as a distinct desired state by Test().

This helper collapses all of those spellings into one: no leading or trailing separator,
single forward slashes, and each segment trimmed of surrounding whitespace.

It does not validate that the path exists; use Resolve-AzDoQueryPath for that.

.PARAMETER Path
The query path to normalize.

.EXAMPLE
Format-AzDoQueryPath -Path '\Shared Queries\Platform\'
Returns 'Shared Queries/Platform'.

.EXAMPLE
Format-AzDoQueryPath -Path 'Shared Queries//Bugs'
Returns 'Shared Queries/Bugs'.
#>
Function Format-AzDoQueryPath
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [String]$Path
    )

    Process
    {
        if ([String]::IsNullOrWhiteSpace($Path))
        {
            return ''
        }

        # Backslashes are accepted because the Azure DevOps UI shows query paths with them,
        # but the API only accepts forward slashes.
        $normalized = $Path -replace '\\', '/'

        # Drop empty segments, which is what a leading, trailing or doubled separator produces.
        $segments = @($normalized -split '/' | ForEach-Object { $_.Trim() } | Where-Object { -not [String]::IsNullOrWhiteSpace($_) })

        return ($segments -join '/')
    }
}
