<#
.SYNOPSIS
Resolves a normalized test suite path to the suite object at that path.

.DESCRIPTION
The Test Plan API has no get-suite-by-path endpoint, so a suite's path is resolved by
walking the flat list of every suite in the plan, matching a name at each level under the
suite found for the previous segment - starting from the plan's root suite. Returns $null
when any segment along the path is missing, rather than throwing, so callers can treat "not
found" as a normal Get() outcome.

.PARAMETER Suites
Every suite in the plan, as returned by Get-DevOpsTestSuite -TestPlanId ... with no -SuiteId.
Each element is expected to carry .id, .name and .parentSuite.id.

.PARAMETER RootSuiteId
The id of the plan's root suite.

.PARAMETER Path
The normalized suite path (see Format-AzDoTestSuitePath), for example 'Regression/Smoke'. An
empty path resolves to the root suite itself.

.EXAMPLE
Resolve-AzDoTestSuitePath -Suites $suites -RootSuiteId 1 -Path 'Regression/Smoke'
#>
Function Resolve-AzDoTestSuitePath
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject])]
    param
    (
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [Object[]]$Suites,

        [Parameter(Mandatory = $true)]
        [Int]$RootSuiteId,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [String]$Path
    )

    $segments = @($Path -split '/' | Where-Object { -not [String]::IsNullOrWhiteSpace($_) })

    if ($segments.Count -eq 0)
    {
        return ($Suites | Where-Object { $_.id -eq $RootSuiteId } | Select-Object -First 1)
    }

    $currentParentId = $RootSuiteId
    $suite = $null

    foreach ($segment in $segments)
    {
        $matches = @($Suites | Where-Object { $_.parentSuite.id -eq $currentParentId -and $_.name -eq $segment })

        if ($matches.Count -eq 0)
        {
            return $null
        }

        $suite = $matches[0]
        $currentParentId = $suite.id
    }

    return $suite
}
