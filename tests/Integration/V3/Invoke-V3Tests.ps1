#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.0.0" }
<#
.SYNOPSIS
    Runner for DSC v3 integration tests.

.DESCRIPTION
    Bootstraps the test environment, dot-sources helper functions, authenticates
    the AzureDevOpsDsc module, then runs Pester against tests/Integration/V3/Resources/.

    Requires:
      - 'dsc' (DSC v3 CLI) on PATH
      - AzureDevOpsDsc module in PSModulePath (built via build.ps1)
      - A populated TestFrameworkConfiguration.json (same schema as the v2 runner)

.PARAMETER TestFrameworkConfigurationPath
    Path to the TestFrameworkConfiguration.json file.

.PARAMETER ResultsPath
    XML output path for NUnit test results. Defaults to C:\Temp\v3-integration-test-results.xml.
#>
param(
    [Parameter(Mandatory)]
    [string]$TestFrameworkConfigurationPath,

    [string]$ResultsPath = 'C:\Temp\v3-integration-test-results.xml'
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
# Import DSC modules

Import-Module AzureDevOpsDsc.Common -ErrorAction Stop
Import-Module AzureDevOpsDscNative  -ErrorAction Stop

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
$pesterConfig.Output.Verbosity   = 'Detailed'
$pesterConfig.TestResult.Enabled = $true
$pesterConfig.TestResult.OutputPath   = $ResultsPath
$pesterConfig.TestResult.OutputFormat = 'NUnitXml'

Invoke-Pester -Configuration $pesterConfig
