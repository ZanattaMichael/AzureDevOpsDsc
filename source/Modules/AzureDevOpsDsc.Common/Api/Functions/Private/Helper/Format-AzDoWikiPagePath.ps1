<#
.SYNOPSIS
Normalizes a wiki page path into the canonical form used by the Wiki Pages API.

.DESCRIPTION
Wiki page paths are forward-slash-delimited and rooted at '/', for example '/Runbooks/On-call'.
Users write them inconsistently: with or without the leading separator, with backslashes copied
from a Windows path, or with a trailing separator. Each spelling would otherwise be treated as a
distinct desired state by Test().

This returns the path with a single leading forward slash, single separators between segments and
no trailing separator. The wiki root is returned as '/'.

.PARAMETER Path
The wiki page path to normalize.

.EXAMPLE
Format-AzDoWikiPagePath -Path 'Runbooks\On-call\'
Returns '/Runbooks/On-call'.
#>
Function Format-AzDoWikiPagePath
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
            return '/'
        }

        # Backslashes are accepted because they turn up in paths copied from Windows Explorer or
        # from other resources in this module, but the Wiki Pages API uses forward slashes.
        $normalized = $Path -replace '\\', '/'

        $segments = @($normalized -split '/' | ForEach-Object { $_.Trim() } | Where-Object { -not [String]::IsNullOrWhiteSpace($_) })

        if ($segments.Count -eq 0)
        {
            return '/'
        }

        return '/' + ($segments -join '/')
    }
}
