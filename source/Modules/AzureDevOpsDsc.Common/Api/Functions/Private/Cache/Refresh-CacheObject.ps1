<#
.SYNOPSIS
    Unloads and reloads the cache object of the specified type.

.DESCRIPTION
    The Refresh-CacheObject function is used to unload and then reload a cache object of a specified type.
    This can be useful when you need to refresh the state of a cache object to ensure it is up-to-date.

.PARAMETER CacheType
    The type of the cache object to be refreshed. This parameter is mandatory and must be one of the valid cache object types returned by the Get-AzDoCacheObjects function.

.EXAMPLE
    Refresh-CacheObject -CacheType 'Project'
    This example unloads and reloads the cache object of type 'Project'.

.NOTES
    The function uses the Remove-Variable cmdlet to unload the cache object and the Import-CacheObject function to reload it.
    Verbose messages are written to provide feedback on the unloading and reloading process.

#>
# Unloads and reloads the cache object of the specified type.
Function Refresh-CacheObject
{
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({$_ -in (Get-AzDoCacheObjects)})]
        [string]
        $CacheType
    )

    # New- and Set- functions export a cache and then refresh it. When the file is the one this
    # session last wrote or read, and the cache in memory is still what went into it, reading it
    # back would change nothing, so skip the reload. A file written by another process, or a
    # cache changed in memory since, still reloads.
    if ($ENV:AZDODSC_CACHE_DIRECTORY)
    {
        $cacheFilePath = [System.IO.Path]::Combine($ENV:AZDODSC_CACHE_DIRECTORY, 'Cache', "$CacheType.clixml")
        if (Test-CacheFileStamp -CacheType $CacheType -Path $cacheFilePath)
        {
            Write-Verbose "[Refresh-CacheObject] The cache object of type '$CacheType' already matches its file. Skipping the reload."
            # Keep the global a List[CacheItem], as a reload would have left it.
            $current = $ExecutionContext.SessionState.PSVariable.GetValue("Global:AzDo$CacheType")
            if ($current -isnot [System.Collections.Generic.List[CacheItem]])
            {
                $list = [System.Collections.Generic.List[CacheItem]]::new()
                foreach ($item in $current) { $list.Add($item) }
                Set-Variable -Name "AzDo$CacheType" -Value $list -Scope Global -Force
            }
            return
        }
    }

    Write-Verbose "[Refresh-CacheObject] Unloading the cache object of type '$CacheType'."

    # Unload the current cache object
    Remove-Variable -Name "AzDo$CacheType" -Scope Global -ErrorAction SilentlyContinue

    Write-Verbose "[Refresh-CacheObject] Reloading the cache object of type '$CacheType'."

    # Reload the cache object
    $null = Import-CacheObject -CacheType $CacheType

}

