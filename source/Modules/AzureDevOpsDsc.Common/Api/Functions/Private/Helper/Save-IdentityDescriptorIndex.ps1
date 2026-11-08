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
        Export-Clixml -InputObject $index -Path $path -Depth 3

        # The index maps descriptors to identities, so it has to stay owner-only like the other caches.
        Protect-AzDoCachePath -Path $path
    }
    catch
    {
        Write-Verbose "[Save-IdentityDescriptorIndex] Could not export index to '$path': $_"
    }
}
