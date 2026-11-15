<#
.SYNOPSIS
Retrieves a cache object of a specified type.

.DESCRIPTION
The Get-CacheObject function is used to retrieve a cache object of a specified type. It first checks if the cache object is available in memory, and if not, it attempts to import it. The function supports different cache types such as Project, Team, Group, and SecurityDescriptor.

.PARAMETER CacheType
Specifies the type of cache object to retrieve. Valid values are 'Project', 'Team', 'Group', and 'SecurityDescriptor'.

.PARAMETER CacheRootPath
Specifies the root path of the cache. By default, it uses the path of the current script.

.EXAMPLE
Get-CacheObject -CacheType Project
Retrieves the cache object of type 'Project'.

.EXAMPLE

Retrieves the cache object of type 'Team' from the specified root path.

.INPUTS
None.

.OUTPUTS
The cache object of the specified type. This is the live in-memory list, not a copy, so it
reflects later Add-CacheItem and Remove-CacheItem calls. Use .Where() rather than piping it
to Where-Object, which receives the list as one object.

.NOTES
This function is part of the AzureDevOpsDsc module.

.LINK
https://github.com/ZanattaMichael/AzureDevOpsDsc

#>
function Get-CacheObject
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({$_ -in (Get-AzDoCacheObjects)})]
        [string]$CacheType
    )

    # This function runs on every cache read. A Write-Verbose call costs a few tenths of a
    # millisecond even when nothing is listening, so the messages are only written when verbose
    # output is on or the module's Write-Verbose is logging to a file.
    $writeVerbose = ($VerbosePreference -ne 'SilentlyContinue') -or (-not [string]::IsNullOrEmpty($env:AZDO_VERBOSELOGGING_FILEPATH))
    if ($writeVerbose)
    {
        Write-Verbose "[Get-ObjectCache] Attempting to retrieve cache object for type: $CacheType"
    }

    # The cache directory comes from the environment. It is only needed here to import a cache
    # that is not in memory yet, which Import-CacheObject does.
    if (-not $ENV:AZDODSC_CACHE_DIRECTORY)
    {
        Throw "The environment variable 'AZDODSC_CACHE_DIRECTORY' is not set. Please set the variable to the path of the cache directory."
    }

    try
    {
        # Attempt to get the variable from the global scope. One lookup through the session state
        # rather than two Get-Variable calls.
        $variable = $ExecutionContext.SessionState.PSVariable.Get("Global:AzDo$CacheType")

        if ($null -ne $variable)
        {
            if ($writeVerbose)
            {
                Write-Verbose "[Get-ObjectCache] Cache object found in memory for type: $CacheType"
            }
            $var = $variable.Value
        }
        else
        {
            if ($writeVerbose)
            {
                Write-Verbose "[Get-ObjectCache] Cache object not found in memory, attempting to import for type: $CacheType"
            }
            $imported = Import-CacheObject -CacheType $CacheType
            # Import-CacheObject sets the global. Read it back rather than using the return value,
            # which PowerShell has already unrolled into a copy (or $null, for an empty cache).
            $var = Get-Variable -Name "AzDo$CacheType" -ValueOnly -Scope Global -ErrorAction SilentlyContinue
            if ($null -eq $var)
            {
                $var = $imported
            }
        }

        # Keep the global as a List[CacheItem], so Add-CacheItem and Remove-CacheItem can change it
        # in place. Set-CacheObject stores an [Object[]]; convert that once here, not on every add.
        if (($null -ne $var) -and ($var -isnot [System.Collections.Generic.List[CacheItem]]) -and ($var -is [System.Collections.IEnumerable]) -and ($var -isnot [string]))
        {
            try
            {
                $var = [System.Collections.Generic.List[CacheItem]]$var
                Set-Variable -Name "AzDo$CacheType" -Value $var -Scope Global -Force
            }
            catch
            {
                Write-Verbose "[Get-ObjectCache] Cache '$CacheType' does not hold CacheItem objects; returning it unchanged."
            }
        }

        if ($null -eq $var)
        {
            return
        }

        # Return the live cache, not a copy. A bare 'return $var' unrolls the list, so every call
        # copied the whole cache and Add-CacheItem then copied it again into a new list.
        if ($writeVerbose)
        {
            Write-Verbose "[Get-ObjectCache] Returning cache object for type: $CacheType"
        }
        return ,$var

    }
    catch
    {
        throw "[Get-ObjectCache] Failed to get cache for Azure DevOps API: $_"
    }
}
