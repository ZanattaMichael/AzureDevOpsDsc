<#
.SYNOPSIS
Appends one timestamped line to a module log file, creating the file owner-only.

.DESCRIPTION
Shared by the Write-Verbose, Write-Warning and Write-Error proxies. A log file collects everything
the module says about an organization - names, identities, URIs, error text from the API - so it
gets the same owner-only permissions as the cache (Protect-AzDoCachePath) when it is first
created. The message is expected to have been through Protect-AzDoSecretString already.

.PARAMETER LogFilePath
The log file to append to.

.PARAMETER Message
The already-redacted message.
#>
function Add-AzDoLogFileEntry
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $LogFilePath,

        [Parameter()]
        [AllowEmptyString()]
        [System.String]
        $Message
    )

    $isNewFile = -not (Test-Path -LiteralPath $LogFilePath)

    if ($isNewFile)
    {
        # Created empty and restricted before the first line is written, so the content is never
        # readable with the default permissions.
        $null = New-Item -Path $LogFilePath -ItemType File -Force
        Protect-AzDoCachePath -Path $LogFilePath
    }

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Add-Content -LiteralPath $LogFilePath -Value "[$timestamp] $Message"
}
