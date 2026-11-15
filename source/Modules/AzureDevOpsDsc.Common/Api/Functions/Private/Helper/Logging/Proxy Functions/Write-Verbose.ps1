<#
.SYNOPSIS
Writes a verbose message to the console and optionally logs it to a file.

.DESCRIPTION
The Write-Verbose function writes a verbose message to the console using the built-in Write-Verbose cmdlet.
specified by the LogFilePath parameter.

.PARAMETER Message
The verbose message to be written to the console and optionally logged to a file.

.PARAMETER LogFilePath
The path to the log file where the verbose message will be appended. If not specified, the value of the

.EXAMPLE
Write-Verbose -Message "This is a verbose message."

This command writes the message "This is a verbose message." to the console and, if the environment variable

.NOTES
The function uses the built-in Write-Verbose cmdlet to write messages to the console. It also checks if the
#>
Function Write-Verbose
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter()]
        [string]$LogFilePath = "$($env:AZDO_VERBOSELOGGING_FILEPATH)"
    )

    # Anything that looks like a credential is redacted before the message reaches the verbose
    # stream (which DSC captures into its own logs) or the log file. Skipped when the message
    # goes nowhere - verbose output is off and there is no log file - to keep that path cheap.
    $writeToLogFile = -not [String]::IsNullOrEmpty($LogFilePath)
    if ($writeToLogFile -or ($VerbosePreference -ne 'SilentlyContinue'))
    {
        $Message = Protect-AzDoSecretString -InputString $Message
    }

    # Call the original Write-Verbose cmdlet
    Microsoft.PowerShell.Utility\Write-Verbose $Message

    # Append the message to the log file, created owner-only
    if ($writeToLogFile)
    {
        Add-AzDoLogFileEntry -LogFilePath $LogFilePath -Message $Message
    }

}
