<#
.SYNOPSIS
Tests whether the in-memory cache of a type still matches its cache file.

.DESCRIPTION
Returns $true when Set-CacheFileStamp recorded a stamp for the cache type, the cache file has the
same last write time and length as it had then, and the global cache variable still holds exactly
the items that were written or read, in the same order. Reloading the file would then give back
what is already in memory.

A file written by another process, or a cache changed in memory since (Add-CacheItem,
Remove-CacheItem, or a list changed directly), fails the test.

.PARAMETER CacheType
The cache type to test.

.PARAMETER Path
The cache file of that type.

.OUTPUTS
System.Boolean

.NOTES
This function is private and should not be used directly.
#>
function Test-CacheFileStamp
{
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $CacheType,

        [Parameter(Mandatory = $true)]
        [string]
        $Path
    )

    if ($Global:AzDoCacheFileStamp -isnot [hashtable])
    {
        return $false
    }

    $stamp = $Global:AzDoCacheFileStamp[$CacheType]
    if ($null -eq $stamp)
    {
        return $false
    }

    try
    {
        $file = [System.IO.FileInfo]::new($Path)
        if ((-not $file.Exists) -or ($file.LastWriteTimeUtc.Ticks -ne $stamp.Ticks) -or ($file.Length -ne $stamp.Length))
        {
            return $false
        }

        $variable = $ExecutionContext.SessionState.PSVariable.Get("Global:AzDo$CacheType")
        if (($null -eq $variable) -or ($null -eq $variable.Value))
        {
            return $false
        }

        [object[]]$items   = $stamp.Items
        [object[]]$current = @($variable.Value)

        # The recorded items are all CacheItem objects, which do not override Equals, so this
        # compares the two sequences by reference.
        return [System.Linq.Enumerable]::SequenceEqual([object[]]$items, [object[]]$current)
    }
    catch
    {
        Write-Verbose "[Test-CacheFileStamp] Could not compare '$CacheType' with its file: $_"
        return $false
    }
}
