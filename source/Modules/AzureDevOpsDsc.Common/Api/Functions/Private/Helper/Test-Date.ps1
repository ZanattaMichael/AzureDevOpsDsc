<#
.SYNOPSIS
    Validates if a given date string matches a specified format.

.PARAMETER DateTime
    The date string to be validated.

.PARAMETER FormatString
    The format string to validate the date against.

.RETURNS
    [Boolean] $true if the date string matches the format, otherwise $false.

.EXAMPLE
    Test-Date -DateTime "2023-10-05" -FormatString "yyyy-MM-dd"
    Returns $true if the date string is in the format "yyyy-MM-dd".

.NOTES
    This function uses [Datetime]::ParseExact to validate the date string.
#>
Function Test-Date {
    param ([String]$DateTime)

    return $null -ne ($DateTime -as [DateTime])
}
