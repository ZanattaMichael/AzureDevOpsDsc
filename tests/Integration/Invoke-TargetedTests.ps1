#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.0.0" }
<#
.SYNOPSIS
    Runs a focused subset of the integration tests — specific files and/or specific
    Describe/Context/It blocks — instead of the whole suite.

.DESCRIPTION
    Invoke-Tests.ps1 runs every *.tests.ps1 under Resources\ (a ~1 hour run). When iterating
    on a handful of failing Context blocks that is wasteful. This script reuses the same test
    framework initialization and teardown but lets you scope the run:

      -TestFile  : one or more test file names (with or without path / .tests.ps1 suffix)
                   to limit Pester discovery to. Greatly speeds up discovery.
      -FullName  : one or more wildcard patterns matched against the full test name
                   ("<Describe> <Context> <It>"). Only matching blocks execute. The
                   Describe-level BeforeAll (which provisions the project/group) still runs,
                   so a single Context can be exercised in isolation.
      -SkipTeardown : skip the pre/post-run teardown (the slowest part). Use only when the
                      target resources are already in a known-clean state.

.EXAMPLE
    # Run only the "Reverting to inherited permissions" context in AzDoProjectPermission
    . .\Invoke-TargetedTests.ps1 -TestFrameworkConfigurationPath .\TestFrameworkConfiguration.json `
        -TestFile AzDoProjectPermission `
        -FullName '*Reverting to inherited permissions*'

.EXAMPLE
    # Run every failing context across two files, skipping teardown for speed
    . .\Invoke-TargetedTests.ps1 -TestFrameworkConfigurationPath .\TestFrameworkConfiguration.json `
        -TestFile AzDoProjectPermission, AzDoOrganizationGroup `
        -FullName '*Update*', '*Reverting*' -SkipTeardown
#>
param(
    [Parameter(Mandatory = $true)]
    [String]$TestFrameworkConfigurationPath,

    # Limit discovery to these test files. Accepts a bare resource name ('AzDoProjectPermission'),
    # a file name ('AzDoProjectPermission.tests.ps1') or a full path.
    [Parameter()]
    [String[]]$TestFile,

    # Wildcard pattern(s) matched against the full test name "<Describe> <Context> <It>".
    [Parameter()]
    [String[]]$FullName,

    # Skip the pre-run and post-run teardown (the slowest part of a run).
    [Parameter()]
    [Switch]$SkipTeardown
)

#
# Dot Source the Supporting Functions (mirrors Invoke-Tests.ps1)

$CurrentLocation = Get-Location

Get-ChildItem -Path "$($CurrentLocation.Path)\Supporting\Functions" -Filter "*.ps1" | ForEach-Object { . $_.FullName }
Get-ChildItem -Path "$($CurrentLocation.Path)\Supporting\API"      -Filter "*.ps1" | ForEach-Object { . $_.FullName }
Get-ChildItem -Path "$($CurrentLocation.Path)\Supporting\APICalls" -Filter "*.ps1" | ForEach-Object { . $_.FullName }

#
# Initialize the test environment
. "$($CurrentLocation.Path)\Supporting\Initalize-TestFramework.ps1" -TestFrameworkConfigurationPath $TestFrameworkConfigurationPath

#
# Pre-run teardown (optional)
if (-not $SkipTeardown)
{
    Write-Host "[Invoke-TargetedTests] Running pre-run teardown to ensure a clean environment..."
    . "$($CurrentLocation.Path)\Supporting\Teardown.ps1" -ClearAll -OrganizationName $GLOBAL:DSCAZDO_OrganizationName -TestFrameworkConfiguration $TestFrameworkConfiguration
    Write-Host "[Invoke-TargetedTests] Pre-run teardown complete."
}
else
{
    Write-Host "[Invoke-TargetedTests] -SkipTeardown specified; skipping pre-run teardown."
}

#
# Resolve the -TestFile names to concrete paths under Resources\
$resourcesPath = "$PSScriptRoot\Resources"
if ($TestFile)
{
    $resolvedPaths = foreach ($tf in $TestFile)
    {
        if (Test-Path -LiteralPath $tf)
        {
            (Resolve-Path -LiteralPath $tf).Path
        }
        else
        {
            # Normalise: strip any .tests.ps1 suffix then re-add it
            $leaf = ($tf -replace '\.tests\.ps1$', '') -replace '\.ps1$', ''
            $candidate = Join-Path -Path $resourcesPath -ChildPath "$leaf.tests.ps1"
            if (Test-Path -LiteralPath $candidate)
            {
                $candidate
            }
            else
            {
                # Fall back to a prefix glob so a bare resource name picks up split variants
                # (e.g. 'AzDoOrganizationGroup' -> *.Description.tests.ps1 + *.NoDescription.tests.ps1).
                $globbed = @(Get-ChildItem -Path $resourcesPath -Filter "$leaf*.tests.ps1" -File | Select-Object -ExpandProperty FullName)
                if ($globbed.Count -eq 0)
                {
                    throw "[Invoke-TargetedTests] Could not resolve test file '$tf' (looked for '$candidate' and '$leaf*.tests.ps1')."
                }
                $globbed
            }
        }
    }
    $runPath = @($resolvedPaths)
    Write-Host "[Invoke-TargetedTests] Scoping discovery to:`n  $($runPath -join "`n  ")"
}
else
{
    $runPath = $resourcesPath
}

#
# Build the Pester configuration
$pesterConfig = New-PesterConfiguration
$pesterConfig.Run.Path           = $runPath
$pesterConfig.Output.Verbosity   = 'Detailed'
$pesterConfig.TestResult.Enabled = $true
$pesterConfig.TestResult.OutputPath   = 'C:\Temp\integration-test-results-targeted.xml'
$pesterConfig.TestResult.OutputFormat = 'NUnitXml'

if ($FullName)
{
    $pesterConfig.Filter.FullName = $FullName
    Write-Host "[Invoke-TargetedTests] Filtering to full-name pattern(s): $($FullName -join ', ')"
}

Invoke-Pester -Configuration $pesterConfig

#
# Post-run teardown (optional)
if (-not $SkipTeardown)
{
    Write-Host "[Invoke-TargetedTests] Running post-run teardown..."
    . "$($CurrentLocation.Path)\Supporting\Teardown.ps1" -ClearAll -OrganizationName $GLOBAL:DSCAZDO_OrganizationName -TestFrameworkConfiguration $TestFrameworkConfiguration
    Write-Host "[Invoke-TargetedTests] Post-run teardown complete."
}
