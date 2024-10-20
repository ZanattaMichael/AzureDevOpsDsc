Function Write-Warning {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter()]
        [string]$LogFilePath = "C:\Temp\warning_log.txt"
    )

    # Call the original Write-Verbose cmdlet to display the message if verbose preference is enabled
    $originalPreference = $VerbosePreference
    $VerbosePreference = 'Continue'
    Microsoft.PowerShell.Utility\Write-Warning $Message
    $VerbosePreference = $originalPreference

    # Append the message to the log file
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $LogFilePath -Value "[$timestamp] $Message"
}
