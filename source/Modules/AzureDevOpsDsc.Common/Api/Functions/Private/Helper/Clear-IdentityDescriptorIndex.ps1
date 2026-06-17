<#
.SYNOPSIS
    Clears the descriptor->identity index in memory and on disk.

.DESCRIPTION
    Part of the flat descriptor->identity index (see Get-IdentityDescriptorIndexItem). Called at the
    start of a cache rebuild (init step 7) so the index stays consistent with the freshly-rebuilt live
    caches.
#>
function Clear-IdentityDescriptorIndex
{
    [CmdletBinding()]
    param()

    $Global:AzDoIdentityDescriptorIndex = @{}
    $path = Get-IdentityDescriptorIndexPath
    if ($path -and (Test-Path -Path $path))
    {
        try { Remove-Item -Path $path -Force -ErrorAction Stop }
        catch { Write-Verbose "[Clear-IdentityDescriptorIndex] Could not remove '$path': $_" }
    }
}
