<#
.SYNOPSIS
Returns a key-to-item index for an in-memory cache list.

.DESCRIPTION
Add-CacheItem and Get-CacheItem used to find a key by scanning the whole cache, which made
filling a cache item by item quadratic. This function keeps one dictionary per cache type, keyed
case-insensitively like PowerShell's -eq, in $Global:AzDoCacheKeyIndex.

The index records the list it was built from and how many items that list held. It is rebuilt
whenever the global has been replaced with a different list or its count no longer matches,
so code that changes a cache without going through Add-CacheItem cannot leave a stale index.

A cache holding the same key twice cannot be indexed one-to-one. The function returns $null
for it, and callers fall back to scanning the list.

.PARAMETER Type
The cache type the list belongs to.

.PARAMETER Cache
The live cache list, as returned by Get-CacheObject.

.OUTPUTS
System.Collections.Generic.Dictionary[string, CacheItem], or $null.

.EXAMPLE
$index = Get-CacheKeyIndex -Type 'LiveProjects' -Cache $cache

.NOTES
This function is private and should not be used directly.
#>
function Get-CacheKeyIndex
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $Type,

        # Untyped and not mandatory on purpose: binding a mandatory, typed collection parameter
        # walks the whole list, which cost more than the dictionary lookup this function exists
        # to provide. The type is checked below instead.
        [Parameter()]
        [AllowNull()]
        [object]
        $Cache
    )

    if ($Cache -isnot [System.Collections.Generic.List[CacheItem]])
    {
        return $null
    }

    if ($Global:AzDoCacheKeyIndex -isnot [hashtable])
    {
        $Global:AzDoCacheKeyIndex = @{}
    }

    $entry = $Global:AzDoCacheKeyIndex[$Type]
    if (($null -ne $entry) -and [object]::ReferenceEquals($entry.List, $Cache) -and ($entry.Map.Count -eq $Cache.Count))
    {
        return ,$entry.Map
    }

    if (($VerbosePreference -ne 'SilentlyContinue') -or (-not [string]::IsNullOrEmpty($env:AZDO_VERBOSELOGGING_FILEPATH)))
    {
        Write-Verbose "[Get-CacheKeyIndex] Building the key index for cache '$Type' ($($Cache.Count) items)."
    }

    $map = [System.Collections.Generic.Dictionary[string, CacheItem]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($item in $Cache)
    {
        if ($null -eq $item -or $map.ContainsKey($item.Key))
        {
            # A duplicate (or a null entry) means the list cannot be indexed one-to-one.
            $null = $Global:AzDoCacheKeyIndex.Remove($Type)
            return $null
        }
        $map[$item.Key] = $item
    }

    $Global:AzDoCacheKeyIndex[$Type] = @{ List = $Cache; Map = $map }
    return ,$map
}
