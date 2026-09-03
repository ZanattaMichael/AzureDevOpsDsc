#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.0.0" }
<#
.SYNOPSIS
    Runner for DSC v3 integration tests.

.DESCRIPTION
    Bootstraps the test environment, dot-sources helper functions, authenticates
    the AzureDevOpsDsc module, then runs Pester against tests/Integration/V3/Resources/.

    Requires:
      - 'dsc' (DSC v3 CLI) on PATH
      - AzureDevOpsDscNative module in PSModulePath (built via build.ps1)
      - A populated TestFrameworkConfiguration.json (same schema as the v2 runner)

.PARAMETER TestFrameworkConfigurationPath
    Path to the TestFrameworkConfiguration.json file.

.PARAMETER ResultsPath
    XML output path for NUnit test results. Defaults to C:\Temp\v3-integration-test-results.xml.

.PARAMETER AllowFailures
    When set, individual test failures are logged as a warning and the script exits 0
    provided the suite genuinely ran. Setup/infrastructure failures - Pester never
    started, the dsc CLI missing, module resolution failed - still exit non-zero, so a
    broken environment cannot silently pass. Mirrors Invoke-Tests.ps1 so the publish
    workflow can let a prerelease proceed despite in-progress v3 tests.
#>
param(
    [Parameter(Mandatory)]
    [string]$TestFrameworkConfigurationPath,

    [string]$ResultsPath = 'C:\Temp\v3-integration-test-results.xml',

    [switch]$AllowFailures
)

$ErrorActionPreference = 'Stop'

$here = $PSScriptRoot

#
# Dot-source the v3 helper library (Assert-DscV3Available, Invoke-DscV3Resource, etc.)

. "$here\Supporting\V3TestHelpers.ps1"

#
# Verify DSC v3 CLI is present

Assert-DscV3Available

#
# Import DSC modules. DscResource.Common is imported explicitly - the v2 initializer
# does the same - so a missing nested module fails here by name rather than midway
# through a resource call.

Import-Module DscResource.Common     -ErrorAction Stop
Import-Module AzureDevOpsDsc.Common  -ErrorAction Stop
Import-Module AzureDevOpsDscNative   -ErrorAction Stop

#
# Initialize the test framework (authenticates the module, sets $Global:V3TestOrg)

. "$here\Supporting\Initialize-V3TestFramework.ps1" -TestFrameworkConfigurationPath $TestFrameworkConfigurationPath

#
# Ensure results directory exists

$resultsDir = Split-Path $ResultsPath -Parent
if (-not (Test-Path $resultsDir)) { New-Item -Path $resultsDir -ItemType Directory -Force | Out-Null }

#
# Run V3 Pester tests

Write-Host "[V3] Starting DSC v3 integration tests..."

$pesterConfig = New-PesterConfiguration
$pesterConfig.Run.Path           = "$here\Resources"
# PassThru is required to see the result. Without it this script cannot tell whether
# any test failed, always exits 0, and every caller - including the release gate in
# the publish workflow - reads a failed run as a successful one.
$pesterConfig.Run.PassThru       = $true
$pesterConfig.Output.Verbosity   = 'Detailed'
$pesterConfig.TestResult.Enabled = $true
$pesterConfig.TestResult.OutputPath   = $ResultsPath
$pesterConfig.TestResult.OutputFormat = 'NUnitXml'

$testResults = Invoke-Pester -Configuration $pesterConfig

#
# Report the outcome with an exit code so callers (CI, the publish release gate) can
# gate on it.

if ($null -eq $testResults)
{
    Write-Error "[V3] Pester did not return a result object - treating the run as failed."
    exit 1
}

Write-Host ("[V3] Passed: {0}, Failed: {1}, Skipped: {2}, NotRun: {3}" -f
    $testResults.PassedCount, $testResults.FailedCount, $testResults.SkippedCount, $testResults.NotRunCount)

if ($testResults.FailedCount -gt 0)
{
    if ($AllowFailures.IsPresent -and $testResults.PassedCount -gt 0)
    {
        # In allow-failures mode (prerelease), let the release proceed but leave a loud,
        # machine-parseable record. The PassedCount > 0 guard ensures we only tolerate
        # real test failures, not a run where every test blew up in setup.
        Write-Warning ("[V3] {0} DSC v3 integration test(s) failed. AllowFailures is set (prerelease), exiting 0." -f $testResults.FailedCount)
        exit 0
    }

    Write-Error ("[V3] {0} DSC v3 integration test(s) failed." -f $testResults.FailedCount)
    exit 1
}

Write-Host "[V3] All DSC v3 integration tests passed."
exit 0
