<#
.SYNOPSIS
    Installs the freshly built AzureDevOpsDsc module into the current user's
    PowerShell Modules directory so the integration tests (which import the
    module by name from PSModulePath) exercise the latest source.

.DESCRIPTION
    Sampler's `build.ps1 -Tasks build` produces the module under
    output\builtModule\AzureDevOpsDsc\<version>. The integration test runner
    (tests\Integration\Invoke-Tests.ps1) imports AzureDevOpsDsc by name, which
    resolves from $HOME\Documents\PowerShell\Modules. This script copies the
    built versioned module over that deployed copy.

.PARAMETER Version
    Module version folder to deploy. Defaults to the single version found in
    the built output.
#>
[CmdletBinding()]
param(
    [string] $Version
)

$ErrorActionPreference = 'Stop'

$repoRoot  = Split-Path -Parent $PSScriptRoot
$builtRoot = Join-Path $repoRoot 'output\builtModule\AzureDevOpsDsc'

if (-not (Test-Path $builtRoot))
{
    throw "[redeploy] Built module not found at '$builtRoot'. Run: .\build.ps1 -Tasks build"
}

if (-not $Version)
{
    $versionDirs = Get-ChildItem $builtRoot -Directory
    if ($versionDirs.Count -ne 1)
    {
        throw "[redeploy] Expected exactly one version under '$builtRoot' but found $($versionDirs.Count). Specify -Version."
    }
    $Version = $versionDirs[0].Name
}

$source = Join-Path $builtRoot $Version
$destModuleRoot = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\Modules\AzureDevOpsDsc'
$dest = Join-Path $destModuleRoot $Version

Write-Host "[redeploy] Source: $source"
Write-Host "[redeploy] Dest  : $dest"

if (-not (Test-Path $source))
{
    throw "[redeploy] Source version path not found: $source"
}

# Replace the deployed versioned module folder with the freshly built one.
if (Test-Path $dest)
{
    Write-Host "[redeploy] Removing existing deployed version folder..."
    Remove-Item -Path $dest -Recurse -Force
}

$null = New-Item -ItemType Directory -Path $dest -Force
Copy-Item -Path (Join-Path $source '*') -Destination $dest -Recurse -Force

Write-Host "[redeploy] Deployed AzureDevOpsDsc $Version."

# Sanity verification
$projFile = Join-Path $dest 'Modules\AzureDevOpsDsc.Common\Resources\Functions\Public\AzDoProject\Get-AzDoProject.ps1'
if (Test-Path $projFile)
{
    $has404 = [bool](Select-String -Path $projFile -Pattern "match '404'" -SimpleMatch)
    Write-Host "[redeploy] Get-AzDoProject 404-catch present: $has404"
}
$markerTotal = (Get-ChildItem (Join-Path $dest 'Modules\AzureDevOpsDsc.Common') -Recurse -Filter *.ps1 |
    Select-String 'falling back to live API lookup' -SimpleMatch).Count
Write-Host "[redeploy] live-fallback marker count in deployed .Common: $markerTotal"
