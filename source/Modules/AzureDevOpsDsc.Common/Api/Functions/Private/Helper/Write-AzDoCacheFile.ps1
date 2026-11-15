<#
.SYNOPSIS
    Writes an object to a file under the cache directory, encrypted where the platform can.

.DESCRIPTION
    The one place a cache file is written. The object is serialized as CLIXML, exactly as
    Export-Clixml would, and then:

      - on Windows the CLIXML is encrypted with DPAPI for the current account
        (Protect-AzDoCacheData) and written after a short marker (Get-AzDoCacheFileHeader). Only
        the account that wrote the file, on the machine it was written on, can read it back;
      - elsewhere there is no DPAPI, so the CLIXML is written as it is.

    On every platform the file is then restricted to its owner (Protect-AzDoCachePath). Outside
    Windows that is the only protection the file has.

    If DPAPI cannot encrypt (for example the account's profile is not loaded), the file is written
    as plain CLIXML and a warning says so. A cache that cannot be written would fail every
    resource that changes something, after the change has already been made in Azure DevOps.

    The cache holds no secrets (Protect-AzDoCacheSecret). It is encrypted because it describes the
    organization - projects, identities, descriptors, ACLs - which is worth keeping from anyone
    who gets hold of a copy of the disk or a backup.

.PARAMETER Path
    The file to write.

.PARAMETER InputObject
    The object to serialize.

.PARAMETER Depth
    The serialization depth. Default 6, as Export-CacheObject uses.

.NOTES
    Read the file back with Read-AzDoCacheFile, not Import-Clixml.
#>
function Write-AzDoCacheFile
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Path,

        # Untyped, so binding does not enumerate or copy a whole cache.
        [Parameter()]
        [AllowNull()]
        [AllowEmptyCollection()]
        [System.Object]
        $InputObject,

        [Parameter()]
        [System.Int32]
        $Depth = 6
    )

    $encrypted = $false

    if (Test-AzDoIsWindows)
    {
        try
        {
            $xml       = [System.Management.Automation.PSSerializer]::Serialize($InputObject, $Depth)
            $protected = Protect-AzDoCacheData -Data ([System.Text.Encoding]::UTF8.GetBytes($xml))
            $header    = Get-AzDoCacheFileHeader

            $bytes = [System.Byte[]]::new($header.Length + $protected.Length)
            [System.Array]::Copy($header, 0, $bytes, 0, $header.Length)
            [System.Array]::Copy($protected, 0, $bytes, $header.Length, $protected.Length)

            [System.IO.File]::WriteAllBytes($Path, $bytes)
            $encrypted = $true
        }
        catch
        {
            Write-Warning "[Write-AzDoCacheFile] Could not encrypt '$Path'; writing it unencrypted, readable by its owner only. $($_.Exception.Message)"
        }
    }

    if (-not $encrypted)
    {
        # Must use -InputObject (not the pipeline): piping an empty collection writes a null file.
        Export-Clixml -InputObject $InputObject -Depth $Depth -LiteralPath $Path
    }

    Protect-AzDoCachePath -Path $Path
}
