<#
.SYNOPSIS
    Decrypts the bytes of a cache file that Protect-AzDoCacheData encrypted.

.DESCRIPTION
    A thin wrapper over the Windows Data Protection API (DPAPI, CurrentUser scope), kept on its own
    so Read-AzDoCacheFile can be unit tested on any platform by mocking it. It throws when the data
    was encrypted by another account or on another machine, and on any platform but Windows.

.PARAMETER Data
    The bytes Protect-AzDoCacheData returned.

.OUTPUTS
    System.Byte[]
#>
function Unprotect-AzDoCacheData
{
    [CmdletBinding()]
    [OutputType([System.Byte[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [System.Byte[]]
        $Data
    )

    $entropy = [System.Text.Encoding]::UTF8.GetBytes('AzureDevOpsDsc.Cache.v1')

    $clear = [System.Security.Cryptography.ProtectedData]::Unprotect(
        $Data,
        $entropy,
        [System.Security.Cryptography.DataProtectionScope]::CurrentUser
    )

    # The comma keeps the byte array whole instead of writing it to the pipeline byte by byte.
    return , $clear
}
