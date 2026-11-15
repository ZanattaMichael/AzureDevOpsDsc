<#
.SYNOPSIS
Writes a warning message to the console and appends it to a log file.

.DESCRIPTION
The Write-Warning function writes a warning message to the console using the original Write-Verbose cmdlet if the verbose preference is enabled. It also appends the warning message to a specified log file with a timestamp.

.PARAMETER Message
The warning message to be written to the console and log file. This parameter is mandatory.

.PARAMETER LogFilePath
The path to the log file where the warning message will be appended. The default path is "C:\Temp\warning_log.txt".

.EXAMPLE
Write-Warning -Message "This is a warning message."

This example writes the warning message "This is a warning message." to the console and appends it to the default log file.

.EXAMPLE
Write-Warning -Message "This is a warning message." -LogFilePath "C:\Logs\custom_warning_log.txt"

This example writes the warning message "This is a warning message." to the console and appends it to the specified log file "C:\Logs\custom_warning_log.txt".

.NOTES
The function temporarily sets the $VerbosePreference to 'Continue' to ensure the warning message is displayed if verbose preference is enabled, and then restores the original preference.
#>
Function Write-Warning
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter()]
        [string]$LogFilePath = "$($env:AZDO_WARNINGLOGGING_FILEPATH)"
    )

    # Anything that looks like a credential is redacted before the message reaches the warning
    # stream (which DSC captures into its own logs) or the log file.
    $writeToLogFile = -not [String]::IsNullOrEmpty($LogFilePath)
    $Message = Protect-AzDoSecretString -InputString $Message

    # Call the original Write-Warning cmdlet
    $originalPreference = $VerbosePreference
    $VerbosePreference = 'Continue'
    Microsoft.PowerShell.Utility\Write-Warning $Message
    $VerbosePreference = $originalPreference

    # Append the message to the log file, created owner-only
    if ($writeToLogFile)
    {
        Add-AzDoLogFileEntry -LogFilePath $LogFilePath -Message $Message
    }

}
