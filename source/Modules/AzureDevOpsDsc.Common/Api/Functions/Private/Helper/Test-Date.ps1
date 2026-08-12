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

    # `-as [DateTime]` parses against the CURRENT THREAD'S CULTURE, so an unambiguous dd/MM/yyyy
    # date (e.g. '24/02/2025') fails to parse on any MM/dd/yyyy-default culture (e.g. en-US, which
    # GitHub's hosted runners default to) even though callers accept both slash conventions.
    # Try each accepted format explicitly, culture-invariant, instead of relying on ambient culture.
    $formats = @(
        'yyyy-MM-ddTHH:mm:ssZ'
        'yyyy-MM-dd'
        'MM/dd/yyyy'
        'dd/MM/yyyy'
    )

    foreach ($format in $formats)
    {
        $parsed = [DateTime]::MinValue
        if ([DateTime]::TryParseExact($DateTime, $format, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::None, [ref]$parsed))
        {
            return $true
        }
    }

    return $false
}
