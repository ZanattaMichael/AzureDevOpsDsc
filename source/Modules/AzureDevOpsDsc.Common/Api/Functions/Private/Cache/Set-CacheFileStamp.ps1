<#
.SYNOPSIS
Records that the in-memory cache of a type matches its cache file.

.DESCRIPTION
New- and Set- resource functions export a cache and then call Refresh-CacheObject, which read
the file that had just been written straight back in. This function notes the file's last write
time and length together with the items that were written (or read), so Test-CacheFileStamp can
tell Refresh-CacheObject that the reload would change nothing.

The stamp is only recorded when the content is exactly what the global cache variable holds, item
for item, and every item is a CacheItem. Anything else clears the stamp, so the next refresh reads
the file as before.

.PARAMETER CacheType
The cache type the file belongs to.

.PARAMETER Path
The cache file that was written or read.

.PARAMETER Content
The items that were written to, or read from, the file.

.NOTES
This function is private and should not be used directly.
#>
function Set-CacheFileStamp
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $CacheType,

        [Parameter(Mandatory = $true)]
        [string]
        $Path,

        # Untyped, so binding does not enumerate or copy the collection.
        [Parameter()]
        [AllowNull()]
        [object]
        $Content
    )

    if ($Global:AzDoCacheFileStamp -isnot [hashtable])
    {
        $Global:AzDoCacheFileStamp = @{}
    }

    $Global:AzDoCacheFileStamp.Remove($CacheType)

    try
    {
        $variable = $ExecutionContext.SessionState.PSVariable.Get("Global:AzDo$CacheType")
        if (($null -eq $variable) -or ($null -eq $variable.Value))
        {
            return
        }

        # A copy, so a caller changing its own array later cannot change the record.
        [object[]]$items   = @($Content).Clone()
        [object[]]$current = @($variable.Value)

        # A List[CacheItem] can only hold CacheItem objects. Anything else is checked item by item.
        if ($variable.Value -isnot [System.Collections.Generic.List[CacheItem]])
        {
            foreach ($item in $items)
            {
                if ($item -isnot [CacheItem])
                {
                    return
                }
            }
        }

        # CacheItem does not override Equals, so this compares the two sequences by reference. It
        # runs in .NET because a PowerShell loop over a large cache cost a sixth of the export.
        if (-not [System.Linq.Enumerable]::SequenceEqual([object[]]$items, [object[]]$current))
        {
            return
        }

        $file = [System.IO.FileInfo]::new($Path)
        if (-not $file.Exists)
        {
            return
        }

        $Global:AzDoCacheFileStamp[$CacheType] = @{
            Items  = $items
            Ticks  = $file.LastWriteTimeUtc.Ticks
            Length = $file.Length
        }
    }
    catch
    {
        # The stamp only saves a reload. Without one the cache file is simply read again.
        Write-Verbose "[Set-CacheFileStamp] No stamp recorded for '$CacheType': $_"
    }
}
