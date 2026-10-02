<#
.SYNOPSIS
Normalizes a pipeline folder path into the canonical form used by the Build folders API.

.DESCRIPTION
Pipeline folder paths are backslash-delimited and rooted at '\' - unlike work item query paths,
which use forward slashes. Users write them inconsistently: with or without the leading
separator, with forward slashes copied from a URL, or with a trailing separator. Each spelling
would otherwise be treated as a distinct desired state by Test().

This returns the path with a single leading backslash, single separators between segments and no
trailing separator. The project root is returned as '\'.

.PARAMETER Path
The pipeline folder path to normalize.

.EXAMPLE
Format-AzDoPipelineFolderPath -Path 'Platform/Release'
Returns '\Platform\Release'.

.EXAMPLE
Format-AzDoPipelineFolderPath -Path '\Platform\Release\'
Returns '\Platform\Release'.
#>
Function Format-AzDoPipelineFolderPath
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
            return '\'
        }

        # Forward slashes are accepted because they turn up in URLs and in paths copied from the
        # query tree, but the Build folders API uses backslashes.
        $normalized = $Path -replace '/', '\'

        $segments = @($normalized -split '\\' | ForEach-Object { $_.Trim() } | Where-Object { -not [String]::IsNullOrWhiteSpace($_) })

        if ($segments.Count -eq 0)
        {
            return '\'
        }

        return '\' + ($segments -join '\')
    }
}
