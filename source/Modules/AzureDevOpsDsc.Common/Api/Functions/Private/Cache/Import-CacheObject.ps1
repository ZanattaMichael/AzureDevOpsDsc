<#
.SYNOPSIS
Imports a cache object for Azure DevOps API.

.DESCRIPTION
The Import-CacheObject function is used to import a cache object for Azure DevOps API. It checks if the cache file exists and imports its content if found. The cache object is then stored in a global variable.

.PARAMETER CacheType
Specifies the type of cache object to import. Valid values are 'Project', 'Team', 'Group', and 'SecurityDescriptor'.

.PARAMETER CacheRootPath
Specifies the root path where the cache directory is located. By default, it uses the current script's root path.

.EXAMPLE


This example imports the cache object for the 'Project' type from the cache directory located at "C:\Cache".

.INPUTS
None.

.OUTPUTS
None.

.NOTES
#>

function Import-CacheObject
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({$_ -in (Get-AzDoCacheObjects)})]
        [string]$CacheType
    )

    # Write initial verbose message
    Write-Verbose "[Import-CacheObject] Starting to import cache object for type: $CacheType"

    # Use the Enviroment Variables to set the Cache Directory Path
    if ($ENV:AZDODSC_CACHE_DIRECTORY)
    {
        $CacheDirectoryPath = Join-Path -Path $ENV:AZDODSC_CACHE_DIRECTORY -ChildPath "Cache"
    }
    else
    {
        Throw "The environment variable 'AZDODSC_CACHE_DIRECTORY' is not set. Please set the variable to the path of the cache directory."
    }

    Write-Verbose "[Import-CacheObject] Cache root path: $CacheDirectoryPath"

    try
    {
        # Determine cache file path
        $cacheFile = Join-Path -Path $CacheDirectoryPath -ChildPath "$CacheType.clixml"

        # Check if cache file exists
        if (-not (Test-Path -Path $cacheFile))
        {
            # Not a warning: caches are imported on first use, so a cache nothing has written yet is normal.
            Write-Verbose "[Import-CacheObject] Cache file not found at path: $cacheFile"
            # Return an empty in-memory cache so callers always receive a valid collection.
            $emptyCache = [System.Collections.Generic.List[CacheItem]]::New()
            Set-Variable -Name "AzDo$CacheType" -Value $emptyCache -Scope Global -Force
            return $emptyCache
        }

        Write-Verbose "[Import-CacheObject] Importing content from cache file at path: $cacheFile"

        # Read-AzDoCacheFile decrypts a file this account encrypted and reads a plain one as before.
        $Content = Read-AzDoCacheFile -Path $cacheFile

        #Set-Variable -Name "AzDo$CacheType" -Value $Content -Scope Global -Force
        Write-Verbose "[Import-CacheObject] Successfully imported cache object for type: $cacheFile"

        # Convert the imported cache object to a list of CacheItem objects
        $newCache = [System.Collections.Generic.List[CacheItem]]::New()

        # If the content is null, skip!
        if ($null -ne $Content)
        {
            # A loop rather than a pipeline: every resource invocation imports the caches it
            # reads, and a cache can hold thousands of items.
            foreach ($importedItem in $Content)
            {
                # If the key is empty, skip the item
                if ([string]::IsNullOrEmpty($importedItem.Key))
                {
                    continue
                }

                # Create a new CacheItem object and add it to the list
                $newCache.Add([CacheItem]::New($importedItem.Key, $importedItem.Value))
            }
        }

        # A file written by an earlier version of the module can hold a secret that a write
        # response echoed. Blank it before the cache is used, so it is not held in memory either.
        $blanked = Protect-AzDoCacheSecret -CacheType $CacheType -Content $newCache -PassThru

        # Update the new cache object
        Set-Variable -Name "AzDo$CacheType" -Value $newCache -Scope Global -Force

        if ($blanked -gt 0)
        {
            # Rewrite the file so the secret does not stay on disk until the next cache write.
            Write-Warning "[Import-CacheObject] The '$CacheType' cache file held $blanked secret value(s) written by an earlier version of the module. They have been removed from the cache and the file is being rewritten."
            try
            {
                Export-CacheObject -CacheType $CacheType -Content $newCache
            }
            catch
            {
                Write-Warning "[Import-CacheObject] Could not rewrite the '$CacheType' cache file. Delete '$cacheFile' to remove the secret from disk. $_"
            }
        }

        # Note what was read, so a Refresh-CacheObject of an unchanged file does not read it again.
        Set-CacheFileStamp -CacheType $CacheType -Path $cacheFile -Content $newCache
        Write-Verbose "[Import-CacheObject] Cache object imported successfully for '$CacheType'."

        # Return the imported cache so Get-CacheObject's import branch yields the collection rather than
        # $null (the global is set above, but callers consume the return value on first import).
        return $newCache

    }
    catch
    {
        throw "[Import-CacheObject] Failed to import cache for Azure DevOps API: $_"
    }
}
