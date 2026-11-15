<#
.SYNOPSIS
    Reads an object from a file under the cache directory, decrypting it when it is encrypted.

.DESCRIPTION
    The counterpart of Write-AzDoCacheFile. A file that starts with the encryption marker
    (Get-AzDoCacheFileHeader) is decrypted with DPAPI (Unprotect-AzDoCacheData) and deserialized.
    Any other file is read with Import-Clixml, so cache files written by earlier versions of the
    module, and those written outside Windows, keep working.

    An encrypted file can only be read by the account that wrote it, on the machine it was written
    on. Anything else throws an error that says how to rebuild the cache.

.PARAMETER Path
    The file to read. It must exist.

.OUTPUTS
    The deserialized object, as Import-Clixml would return it.
#>
function Read-AzDoCacheFile
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Path
    )

    $header      = Get-AzDoCacheFileHeader
    $isEncrypted = $false

    # Read only the first bytes to tell the two formats apart; a plain file is left to Import-Clixml.
    $stream = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)
    try
    {
        if ($stream.Length -ge $header.Length)
        {
            $start = [System.Byte[]]::new($header.Length)
            $read  = 0
            while ($read -lt $start.Length)
            {
                $count = $stream.Read($start, $read, $start.Length - $read)
                if ($count -le 0) { break }
                $read += $count
            }

            $isEncrypted = ($read -eq $header.Length) -and [System.Linq.Enumerable]::SequenceEqual([System.Byte[]]$start, [System.Byte[]]$header)

            if ($isEncrypted)
            {
                $protected = [System.Byte[]]::new($stream.Length - $header.Length)
                $read      = 0
                while ($read -lt $protected.Length)
                {
                    $count = $stream.Read($protected, $read, $protected.Length - $read)
                    if ($count -le 0) { break }
                    $read += $count
                }
            }
        }
    }
    finally
    {
        $stream.Dispose()
    }

    if (-not $isEncrypted)
    {
        # The comma hands a deserialized list back whole, as Import-Clixml wrote it, rather than
        # unrolled (which would turn a one-item cache into a bare item and an empty one into $null).
        $imported = Import-Clixml -LiteralPath $Path
        return , $imported
    }

    try
    {
        $clear = Unprotect-AzDoCacheData -Data $protected
    }
    catch
    {
        throw "[Read-AzDoCacheFile] '$Path' is encrypted and could not be decrypted. A cache file can only be read by the account that wrote it, on the machine it was written on. Delete the file, or run New-AzDoAuthenticationProvider again as this account, to rebuild the cache. $($_.Exception.Message)"
    }

    $deserialized = [System.Management.Automation.PSSerializer]::Deserialize([System.Text.Encoding]::UTF8.GetString($clear))
    return , $deserialized
}
