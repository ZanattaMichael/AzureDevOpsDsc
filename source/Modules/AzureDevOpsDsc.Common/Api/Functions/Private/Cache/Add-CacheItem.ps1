<#
.SYNOPSIS
Add a cache item to the cache.

.DESCRIPTION
Adds a cache item to the cache with a specified key, value, and type.

.PARAMETER Key
The key of the cache item to add.

.PARAMETER Value
The value of the cache item to add.

.PARAMETER Type
The type of the cache item to add. Valid values are 'Project', 'Team', 'Group', 'SecurityDescriptor'.

.EXAMPLE
Add-CacheItem -Key 'MyKey' -Value 'MyValue' -Type 'Project'

.NOTES
This function is private and should not be used directly.
#>
Function Add-CacheItem
{
    [CmdletBinding()]
    param (
        # The key of the cache item to add
        [Parameter(Mandatory = $true)]
        [string]
        $Key,

        # The value of the cache item to add
        [Parameter(Mandatory = $true)]
        [object]
        $Value,

        # The type of the cache item to add
        [Parameter(Mandatory = $true)]
        [ValidateScript({$_ -in (Get-AzDoCacheObjects)})]
        [string]
        $Type,

        # Suppress warning messages
        [switch]
        $SuppressWarning
    )

    # Adding to a cache happens once per object when a cache is filled. A Write-Verbose call costs
    # a few tenths of a millisecond even when nothing is listening, so the messages are only
    # written when verbose output is on or the module's Write-Verbose is logging to a file.
    $writeVerbose = ($VerbosePreference -ne 'SilentlyContinue') -or (-not [string]::IsNullOrEmpty($env:AZDO_VERBOSELOGGING_FILEPATH))

    if ($writeVerbose) { Write-Verbose "[Add-CacheItem] Retrieving the current cache." }
    # Get-CacheObject returns the live list, so the changes below are made in place rather than
    # on a copy of the whole cache.
    $liveCache = Get-CacheObject -CacheType $Type
    [System.Collections.Generic.List[CacheItem]]$cache = $liveCache
    # True when Get-CacheObject handed back the list the global variable already holds.
    $isLiveCache = ($null -ne $cache) -and [object]::ReferenceEquals($liveCache, $cache)

    # If there is no cache yet, create one. An empty list is the live cache and is filled in
    # place, so anyone already holding it sees the new item.
    if ($null -eq $cache)
    {
        if ($writeVerbose) { Write-Verbose "[Add-CacheItem] Cache is empty. Creating new cache." }
        $cache = [System.Collections.Generic.List[CacheItem]]::New()
    }

    if ($writeVerbose) { Write-Verbose "[Add-CacheItem] Creating new cache item with key: '$Key'." }
    $cacheItem = [CacheItem]::New($Key, $Value)

    # A write response can echo the secrets that were sent (a secret variable's value, a service
    # connection's key). Blank them before the item is stored, so the cache never holds one, in
    # memory or on disk. Only three cache types can carry one; the rest skip the call.
    if (($Type -eq 'LiveVariableGroups') -or ($Type -eq 'LiveServiceConnections') -or ($Type -eq 'LiveAuditStreams'))
    {
        Protect-AzDoCacheSecret -CacheType $Type -Content $cacheItem
    }

    if ($writeVerbose) { Write-Verbose "[Add-CacheItem] Checking if the cache already contains the key: '$Key'." }
    # A dictionary lookup instead of a Where-Object scan, which made filling a cache quadratic.
    $index = Get-CacheKeyIndex -Type $Type -Cache $cache
    if ($null -ne $index)
    {
        $existingItem = $null
        $null = $index.TryGetValue($Key, [ref]$existingItem)
    }
    else
    {
        # The cache holds a duplicate key, so it cannot be indexed. Scan it instead.
        $existingItem = $cache.Where({ $_.Key -eq $Key })
    }

    if ($existingItem)
    {
        # If the cache already contains the key, remove the existing item
        if ($SuppressWarning.IsPresent)
        {
            Write-Verbose "[Add-CacheItem] A cache item with the key '$Key' already exists. Flushing key from the cache."
        }
        else
        {
            Write-Warning "[Add-CacheItem] A cache item with the key '$Key' already exists. Flushing key from the cache."
        }

        if ($null -ne $index)
        {
            # An indexed cache holds each key once, so the item the index found is the only one.
            $null = $cache.Remove($existingItem)
            $null = $index.Remove($Key)
        }
        else
        {
            # Remove every item with this key, walking backwards so the indexes still to be
            # visited do not shift.
            for ($i = $cache.Count - 1; $i -ge 0; $i--)
            {
                if ($cache[$i].Key -eq $Key)
                {
                    $cache.RemoveAt($i)
                }
            }
        }
    }

    if ($writeVerbose) { Write-Verbose "[Add-CacheItem] Adding new cache item with key: '$Key'." }
    $cache.Add($cacheItem)
    if ($null -ne $index)
    {
        $index[$Key] = $cacheItem
    }

    # Update the memory cache. This is the same list in the usual case, but it is a new one when
    # there was no cache yet or the global held something other than a List[CacheItem].
    if (-not $isLiveCache)
    {
        Set-Variable -Name "AzDo$Type" -Value $cache -Scope Global
    }

    if ($writeVerbose) { Write-Verbose "[Add-CacheItem] Cache item with key: '$Key' successfully added." }
}
