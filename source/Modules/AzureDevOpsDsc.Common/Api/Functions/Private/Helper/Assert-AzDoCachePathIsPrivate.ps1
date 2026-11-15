<#
.SYNOPSIS
Throws when the cache directory could have been written by another account.

.DESCRIPTION
ModuleSettings.clixml decides which organization the module talks to and with which credential, and
the cache files map names to identities. An account that can write either can redirect a
permission grant, so they are only trusted when the directory belongs to the account reading it
and nobody else has access.

On Linux and macOS the directory must be owned by the current user (or by root) and carry no group
or other permissions - what Protect-AzDoCachePath sets. The check is not made on Windows, where
the credential in the file is DPAPI-encrypted for the account that wrote it and a file from
another account cannot be decrypted at all.

Setting the AZDODSC_ALLOW_SHARED_CACHE_DIRECTORY environment variable to 1 turns the failure into
a warning, for a directory whose permissions cannot be changed (a mounted volume in a container).

.PARAMETER Path
The cache directory. Defaults to AZDODSC_CACHE_DIRECTORY.
#>
function Assert-AzDoCachePathIsPrivate
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [AllowNull()]
        [AllowEmptyString()]
        [System.String]
        $Path = $env:AZDODSC_CACHE_DIRECTORY
    )

    if ([System.String]::IsNullOrEmpty($Path) -or (Test-AzDoIsWindows) -or -not (Test-Path -LiteralPath $Path))
    {
        return
    }

    $item    = Get-Item -LiteralPath $Path -Force
    $problem = $null

    # 'drwx------': the last six characters are the group and other permissions.
    $mode = [System.String]$item.UnixMode
    if (($mode.Length -ge 10) -and ($mode.Substring(4, 6) -ne '------'))
    {
        $problem = "its permissions are '$mode', which lets other accounts in"
    }

    $owner = [System.String]$item.User
    if (($null -eq $problem) -and (-not [System.String]::IsNullOrEmpty($owner)) -and
        ($owner -cne [System.Environment]::UserName) -and ($owner -cne 'root'))
    {
        $problem = "it is owned by '$owner', not by '$([System.Environment]::UserName)'"
    }

    if ($null -eq $problem)
    {
        return
    }

    $message = "[Assert-AzDoCachePathIsPrivate] The cache directory '$Path' is not private: $problem. Its contents decide which credential is used and which identities receive permissions, so it has not been read. Run 'chmod 700' on it as its owner, or run New-AzDoAuthenticationProvider again as this account."

    if ($env:AZDODSC_ALLOW_SHARED_CACHE_DIRECTORY -eq '1')
    {
        Write-Warning "$message Continuing because AZDODSC_ALLOW_SHARED_CACHE_DIRECTORY is set."
        return
    }

    throw $message
}
