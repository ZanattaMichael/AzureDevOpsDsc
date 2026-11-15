<#
.SYNOPSIS
Logs an error message to a specified log file and displays the error message.

.DESCRIPTION
The Write-Error function logs an error message to a specified log file and displays the error message using the original Write-Error cmdlet.
It appends the error message with a timestamp to the log file.

.PARAMETER Message
The error message to be logged and displayed. This parameter is mandatory.

.PARAMETER LogFilePath
The path to the log file where the error message will be appended. The default path is "C:\Temp\error_log.txt".

.EXAMPLE
Write-Error -Message "An unexpected error occurred."

This example logs the error message "An unexpected error occurred." to the default log file and displays the error message.

.EXAMPLE
Write-Error -Message "An unexpected error occurred." -LogFilePath "C:\Logs\custom_error_log.txt"

This example logs the error message "An unexpected error occurred." to the specified log file "C:\Logs\custom_error_log.txt" and displays the error message.

.NOTES
The function uses the original Write-Error cmdlet from the Microsoft.PowerShell.Utility module to display the error message.
#>
Function Write-Error
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter()]
        [string]$LogFilePath = "$($env:AZDO_ERRORLOGGING_FILEPATH)"
    )

    # Anything that looks like a credential is redacted before the message reaches the error
    # stream (which DSC captures into its own logs) or the log file.
    $writeToLogFile = -not [String]::IsNullOrEmpty($LogFilePath)
    $Message = Protect-AzDoSecretString -InputString $Message

    # Call the original Write-Error cmdlet
    Microsoft.PowerShell.Utility\Write-Error $Message

    # Append the message to the log file, created owner-only
    if ($writeToLogFile)
    {
        Add-AzDoLogFileEntry -LogFilePath $LogFilePath -Message $Message
    }

}
