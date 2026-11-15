<#
.SYNOPSIS
    Returns the bytes that mark a cache file as encrypted.

.DESCRIPTION
    An encrypted cache file is this marker followed by the DPAPI-protected CLIXML. A plain CLIXML
    file starts with '<' (or a byte order mark), so the first bytes of a file say which it is.
    Write-AzDoCacheFile writes the marker and Read-AzDoCacheFile looks for it.

.OUTPUTS
    System.Byte[]
#>
function Get-AzDoCacheFileHeader
{
    [CmdletBinding()]
    [OutputType([System.Byte[]])]
    param ()

    return , [System.Text.Encoding]::ASCII.GetBytes("AZDODSC-DPAPI-1`n")
}
