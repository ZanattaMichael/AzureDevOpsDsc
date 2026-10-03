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

    Write-Verbose "[Add-CacheItem] Retrieving the current cache."
    # Get-CacheObject returns the live list, so the changes below are made in place rather than
    # on a copy of the whole cache.
    [System.Collections.Generic.List[CacheItem]]$cache = Get-CacheObject -CacheType $Type

    # If there is no cache yet, create one. An empty list is the live cache and is filled in
    # place, so anyone already holding it sees the new item.
    if ($null -eq $cache)
    {
        Write-Verbose "[Add-CacheItem] Cache is empty. Creating new cache."
        $cache = [System.Collections.Generic.List[CacheItem]]::New()
    }

    Write-Verbose "[Add-CacheItem] Creating new cache item with key: '$Key'."
    $cacheItem = [CacheItem]::New($Key, $Value)

    Write-Verbose "[Add-CacheItem] Checking if the cache already contains the key: '$Key'."
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

        # Remove every item with this key, walking backwards so the indexes still to be visited
        # do not shift.
        for ($i = $cache.Count - 1; $i -ge 0; $i--)
        {
            if ($cache[$i].Key -eq $Key)
            {
                $cache.RemoveAt($i)
            }
        }
        if ($null -ne $index)
        {
            $null = $index.Remove($Key)
        }
    }

    Write-Verbose "[Add-CacheItem] Adding new cache item with key: '$Key'."
    $cache.Add($cacheItem)
    if ($null -ne $index)
    {
        $index[$Key] = $cacheItem
    }

    # Update the memory cache. This is the same list in the usual case, but it is a new one when
    # there was no cache yet or the global held something other than a List[CacheItem].
    Set-Variable -Name "AzDo$Type" -Value $cache -Scope Global

    Write-Verbose "[Add-CacheItem] Cache item with key: '$Key' successfully added."
}
