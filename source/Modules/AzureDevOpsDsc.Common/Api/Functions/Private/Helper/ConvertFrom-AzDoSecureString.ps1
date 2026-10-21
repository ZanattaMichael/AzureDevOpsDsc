<#
.SYNOPSIS
    Decodes a SecureString to a plain string correctly on every platform.

.DESCRIPTION
    SecureStringToBSTR always produces a UTF-16 buffer. On Windows PtrToStringAuto reads it as
    UTF-16, but on Linux and macOS "Auto" means UTF-8, so the same call returns garbage (usually
    the first character followed by nothing, or a string of replacement characters). This helper
    picks PtrToStringUni off Windows and PtrToStringAuto on it, and always frees the BSTR, so a
    credential decoded here is the credential that was stored.

    Every place in the module that turns a SecureString back into text should call this rather
    than inlining the Marshal calls.

.PARAMETER SecureString
    The SecureString to decode.

.OUTPUTS
    System.String

.EXAMPLE
    $plain = ConvertFrom-AzDoSecureString -SecureString $cachedToken.access_token
#>
Function ConvertFrom-AzDoSecureString
{
    [CmdletBinding()]
    [OutputType([String])]
    param (
        [Parameter(Mandatory = $true)]
        [SecureString]
        $SecureString
    )

    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
    try
    {
        $isWindowsPlatform = [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform(
            [System.Runtime.InteropServices.OSPlatform]::Windows
        )

        if ($isWindowsPlatform)
        {
            return [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
        }

        return [System.Runtime.InteropServices.Marshal]::PtrToStringUni($bstr)
    }
    finally
    {
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
}
