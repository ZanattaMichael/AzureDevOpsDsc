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
        [Object]$object  # Define a parameter to accept a string input
    )

    # Test if the object is a string type.
    if ($object -is [string]) {
        $string = $object
    } elseif ($object -is [datetime]) {
        return $object.ToString('yyyyMMdd')
    }

    # Type cast the input string as a DateTime object
    $dateTime = $string -as [datetime]

    # Check if the conversion was successful (i.e., $dateTime is not null)
    if ($null -eq $dateTime) {
        # If conversion failed, default the dateTime to January 1, 1900
        $dateTime = '01-01-1900' -as [datetime]
    }

    # Return the formatted date as a string in 'yyyyMMdd' format
    return $dateTime.ToString('yyyyMMdd')
}

