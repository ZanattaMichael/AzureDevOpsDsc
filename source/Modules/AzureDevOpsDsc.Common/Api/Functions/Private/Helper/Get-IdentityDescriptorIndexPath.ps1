<#
.SYNOPSIS
    Returns the absolute path to the descriptor->identity index clixml file.

.DESCRIPTION
    Part of the flat descriptor->identity index (see Get-IdentityDescriptorIndexItem). Returns $null
    when no cache directory is configured so callers can no-op gracefully.
#>
function Get-IdentityDescriptorIndexPath
{
    [CmdletBinding()]
    [OutputType([string])]
    param()

    if ([string]::IsNullOrEmpty($ENV:AZDODSC_CACHE_DIRECTORY)) { return $null }
    return (Join-Path -Path $ENV:AZDODSC_CACHE_DIRECTORY -ChildPath 'Cache\IdentityDescriptorIndex.clixml')
}
