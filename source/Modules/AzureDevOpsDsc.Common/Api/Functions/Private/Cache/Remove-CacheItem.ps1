<#
.SYNOPSIS
Removes an item from the Azure DevOps cache.

.DESCRIPTION
The Remove-CacheItem function is used to remove an item from the Azure DevOps cache. It takes a key and a type as parameters. The key is the identifier of the item to be removed, and the type specifies the type of cache (Project, Team, Group, or SecurityDescriptor) from which the item should be removed.

.PARAMETER Key
The key of the item to be removed from the cache.

.PARAMETER Type
The type of cache from which the item should be removed. Valid values are 'Project', 'Team', 'Group', and 'SecurityDescriptor'.

.EXAMPLE
Remove-CacheItem -Key "myKey" -Type "Project"
Removes the item with the key "myKey" from the Project cache.

.EXAMPLE
Remove-CacheItem -Key "anotherKey" -Type "Group"
Removes the item with the key "anotherKey" from the Group cache.
#>
Function Remove-CacheItem
{
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $Key,

        [Parameter(Mandatory = $true)]
        [ValidateScript({$_ -in (Get-AzDoCacheObjects)})]
        [string]
        $Type
    )

    Write-Verbose "[Remove-CacheItem] Retrieving the current cache."
    #$cache = Get-AzDevOpsCache -CacheType $Type
    [System.Collections.Generic.List[CacheItem]]$cache = Get-CacheObject -CacheType $Type

    Write-Verbose "[Remove-CacheItem] Removing the cache item with the key: '$Key'."

    # An absent or empty cache is not an error - there is simply nothing to remove. Without
    # this guard $cache.Count is $null, '0 .. $null' evaluates to 0..0, and the indexing below
    # fails with "Cannot index into a null array". AzDoSecureFile's Remove hit exactly that.
    if ($null -eq $cache -or $cache.Count -eq 0)
    {
        Write-Verbose "[Remove-CacheItem] Cache '$Type' is empty - nothing to remove."
        return
    }

    # If the cache has a length of 1, and the key matches, remove the cache
    if ($cache.Count -eq 1 -and $cache[0].Key -eq $Key)
    {
        Write-Verbose "[Remove-CacheItem] Cache has a length of 1 and the key matches. Removing the cache."
        Set-Variable -Name "AzDo$Type" -Value ([System.Collections.Generic.List[CacheItem]]::New()) -Scope Global
        return
    }

    # Walk backwards so each RemoveAt leaves the indexes still to be examined unchanged.
    # The previous form - '0 .. $cache.Count | ... | ForEach-Object { $cache.RemoveAt($_) }' -
    # was wrong twice over: the range is inclusive, so it indexed one past the end, and
    # removing by index while later indexes were still pending shifted them underneath it.
    for ($index = $cache.Count - 1; $index -ge 0; $index--)
    {
        if ($cache[$index].Key -eq $Key)
        {
            $cache.RemoveAt($index)
        }
    }

    # Update the memory cache
    Set-Variable -Name "AzDo$Type" -Value $cache -Scope Global

}
