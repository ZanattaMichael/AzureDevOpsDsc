<#
.SYNOPSIS
Decodes the hex/UTF-16LE ref segments the Git Repositories security namespace returns inside an
ACL token back into a human-readable branch or tag name.

.DESCRIPTION
The inverse of ConvertTo-GitRefToken. Splits the encoded token on '/', hex-decodes each segment as
UTF-16LE, and rejoins the decoded segments with '/' to recover the ref name exactly as a user would
write it (e.g. 'release/1.0').

.PARAMETER EncodedRef
The hex/UTF-16LE-encoded ref segments as returned by the API, e.g. '6d00610069006e00' or
'72656c65617365/312e30' (two encoded segments for 'release/1.0').

.EXAMPLE
ConvertFrom-GitRefToken -EncodedRef '6d00610069006e00'
Returns 'main'.
#>
Function ConvertFrom-GitRefToken
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]$EncodedRef
    )

    Process
    {
        $segments = $EncodedRef -split '/'

        $decodedSegments = ForEach ($segment in $segments)
        {
            $byteCount = [Math]::Floor($segment.Length / 2)
            $bytes = [Byte[]]::new($byteCount)
            for ($i = 0; $i -lt $byteCount; $i++)
            {
                $bytes[$i] = [Convert]::ToByte($segment.Substring($i * 2, 2), 16)
            }
            [System.Text.Encoding]::Unicode.GetString($bytes)
        }

        return ($decodedSegments -join '/')
    }
}
