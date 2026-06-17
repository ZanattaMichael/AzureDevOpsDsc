<#
.SYNOPSIS
Formats a string as a date in 'yyyyMMdd' format.

.PARAMETER string
The string to be formatted as a date.

.RETURNS
String
The formatted date string in 'yyyyMMdd' format.

.EXAMPLE
PS> Format-Date -string "2023-10-05"
20231005

.NOTES
If the input string cannot be cast to a valid date, the function defaults to '01-01-1900'.
#>
Function Format-Date {
    param(
        [Object]$object
    )

    # -as [datetime] handles strings, DateTime, and Deserialized.System.DateTime uniformly.
    # Fall back to 01-01-1900 when conversion fails.
    $dateTime = $object -as [datetime]
    if ($null -eq $dateTime) { $dateTime = [datetime]'01-01-1900' }

    return $dateTime.ToString('yyyyMMdd')
}

