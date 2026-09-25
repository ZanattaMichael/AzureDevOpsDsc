<#
.SYNOPSIS
Normalizes a test suite path into the canonical form used to address suites under a plan's
root suite.

.DESCRIPTION
A test suite's identity in this module is its path of suite names under the plan's root
suite, for example 'Regression/Smoke'. Users write this inconsistently - with backslashes
copied from the Azure DevOps UI, with a leading or trailing slash, or with doubled
separators - and each spelling would otherwise be treated as a distinct desired state by
Test(). This collapses all of those spellings into one: no leading or trailing separator,
single forward slashes, and each segment trimmed of surrounding whitespace.

.PARAMETER Path
The suite path to normalize.

.EXAMPLE
Format-AzDoTestSuitePath -Path '\Regression\Smoke\'
Returns 'Regression/Smoke'.
#>
Function Format-AzDoTestSuitePath
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [String]$Path
    )

    Process
    {
        if ([String]::IsNullOrWhiteSpace($Path))
        {
            return ''
        }

        $normalized = $Path -replace '\\', '/'
        $segments = @($normalized -split '/' | ForEach-Object { $_.Trim() } | Where-Object { -not [String]::IsNullOrWhiteSpace($_) })

        return ($segments -join '/')
    }
}
