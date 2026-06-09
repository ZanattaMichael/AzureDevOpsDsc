#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.0.0" }
param(
    [Parameter(Mandatory = $true)]
    [String]$TestFrameworkConfigurationPath
)

#
# Dot Source the Supporting Functions

$CurrentLocation = Get-Location

Get-ChildItem -Path "$($CurrentLocation.Path)\Supporting\Functions" -Filter "*.ps1" | ForEach-Object { . $_.FullName }

#
# Load API helpers (needed for teardown)

Get-ChildItem -Path "$($CurrentLocation.Path)\Supporting\API" -Filter "*.ps1" | ForEach-Object { . $_.FullName }
Get-ChildItem -Path "$($CurrentLocation.Path)\Supporting\APICalls" -Filter "*.ps1" | ForEach-Object { . $_.FullName }

#
# Firstly Initialize the test environment
. "$($CurrentLocation.Path)\Supporting\Initalize-TestFramework.ps1" -TestFrameworkConfigurationPath $TestFrameworkConfigurationPath

#
# Pre-run teardown: ensure a clean slate before tests start
# This removes any resources left over from a previous (possibly failed) test run.

Write-Host "[Invoke-Tests] Running pre-run teardown to ensure a clean environment..."
. "$($CurrentLocation.Path)\Supporting\Teardown.ps1" -ClearAll -OrganizationName $GLOBAL:DSCAZDO_OrganizationName -TestFrameworkConfiguration $TestFrameworkConfiguration
Write-Host "[Invoke-Tests] Pre-run teardown complete."

#
# Trigger the Tests

Invoke-Pester -Path "$PSScriptRoot\Resources"

#
# Post-run teardown: clean up all resources created during the test run

Write-Host "[Invoke-Tests] Running post-run teardown..."
. "$($CurrentLocation.Path)\Supporting\Teardown.ps1" -ClearAll -OrganizationName $GLOBAL:DSCAZDO_OrganizationName -TestFrameworkConfiguration $TestFrameworkConfiguration
Write-Host "[Invoke-Tests] Post-run teardown complete."
