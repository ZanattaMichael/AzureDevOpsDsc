<#
.SYNOPSIS
    Returns the in-memory descriptor->identity index hashtable, hydrating it from disk on first use.

.DESCRIPTION
    Part of the flat descriptor->identity index (see Get-IdentityDescriptorIndexItem). The index is a
    hashtable keyed by ACL descriptor whose values are flat all-string records. It is cached in
    $Global:AzDoIdentityDescriptorIndex for the lifetime of the runspace and lazily loaded from the
    clixml file the first time it is needed.
#>
function Get-IdentityDescriptorIndex
{
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    if ($Global:AzDoIdentityDescriptorIndex -is [hashtable]) { return $Global:AzDoIdentityDescriptorIndex }

    $index = @{}
    $path  = Get-IdentityDescriptorIndexPath
    if ($path -and (Test-Path -Path $path))
    {
        try
        {
            $imported = Import-Clixml -Path $path
            if ($imported -is [hashtable]) { $index = $imported }
        }
        catch
        {
            Write-Verbose "[Get-IdentityDescriptorIndex] Could not import index from '$path': $_"
        }
    }

    $Global:AzDoIdentityDescriptorIndex = $index
    return $index
}
