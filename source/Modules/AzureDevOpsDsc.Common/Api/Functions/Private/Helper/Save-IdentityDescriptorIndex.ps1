<#
.SYNOPSIS
    Persists the in-memory descriptor->identity index to its clixml file.

.DESCRIPTION
    Part of the flat descriptor->identity index (see Get-IdentityDescriptorIndexItem). Safe to call
    repeatedly; a no-op when no cache directory is configured. Persistence is intentionally independent
    of the shared Import/Export cache layer so the index cannot be affected by that layer's behaviour.
#>
function Save-IdentityDescriptorIndex
{
    [CmdletBinding()]
    param()

    $path = Get-IdentityDescriptorIndexPath
    if (-not $path) { return }

    $index = Get-IdentityDescriptorIndex
    try
    {
        $parent = Split-Path -Path $path -Parent
        if (-not (Test-Path -Path $parent))
        {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
            Protect-AzDoCachePath -Path $parent
        }
        # The index maps descriptors to identities, so it is encrypted for this account on Windows
        # and kept owner-only everywhere, like the other caches.
        Write-AzDoCacheFile -Path $path -InputObject $index -Depth 3
    }
    catch
    {
        Write-Verbose "[Save-IdentityDescriptorIndex] Could not export index to '$path': $_"
    }
}
