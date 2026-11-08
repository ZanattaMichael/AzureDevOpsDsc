<#
.SYNOPSIS
    Reports whether the module is running on Windows.

.DESCRIPTION
    A one-line platform probe kept in its own function so callers that behave differently per
    platform (Protect-AzDoCachePath) can be unit tested on any platform by mocking it. Windows
    PowerShell 5.1 has no $IsWindows automatic variable and only runs on Windows, so it reports
    $true there; PowerShell 7 reports the automatic variable.

.OUTPUTS
    System.Boolean
#>
function Test-AzDoIsWindows
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param()

    if ($PSVersionTable.PSVersion.Major -le 5)
    {
        return $true
    }

    return [bool]$IsWindows
}
