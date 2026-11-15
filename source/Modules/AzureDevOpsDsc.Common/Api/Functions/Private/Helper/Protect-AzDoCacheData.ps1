<#
.SYNOPSIS
    Encrypts the bytes of a cache file for the current Windows account.

.DESCRIPTION
    A thin wrapper over the Windows Data Protection API (DPAPI, CurrentUser scope), kept on its own
    so Write-AzDoCacheFile can be unit tested on any platform by mocking it. The result can only be
    decrypted by the same account on the same machine (Unprotect-AzDoCacheData), which is how
    Export-Clixml already protects the credential in ModuleSettings.clixml.

    DPAPI exists on Windows only; elsewhere this throws PlatformNotSupportedException, and
    Write-AzDoCacheFile does not call it.

.PARAMETER Data
    The bytes to encrypt.

.OUTPUTS
    System.Byte[]
#>
function Protect-AzDoCacheData
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

    # Not a secret: it only keeps the output from being read back by an unrelated DPAPI caller.
    $entropy = [System.Text.Encoding]::UTF8.GetBytes('AzureDevOpsDsc.Cache.v1')

    $protected = [System.Security.Cryptography.ProtectedData]::Protect(
        $Data,
        $entropy,
        [System.Security.Cryptography.DataProtectionScope]::CurrentUser
    )

    # The comma keeps the byte array whole instead of writing it to the pipeline byte by byte.
    return , $protected
}
