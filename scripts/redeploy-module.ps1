<#
.SYNOPSIS
    Points the current PowerShell session at the freshly built AzureDevOpsDscNative
    module, so the integration tests (which import the module by name from
    PSModulePath) exercise the latest source.

.DESCRIPTION
    Sampler's `build.ps1 -Tasks build` produces the module under
    output\builtModule\AzureDevOpsDscNative\<version>. This script puts that folder,
    and the nested Modules folder holding AzureDevOpsDsc.Common and DscResource.Common,
    at the front of $env:PSModulePath for the current process.

    Nothing is copied into a standard module folder (<MyDocuments>\PowerShell\Modules,
    Program Files and so on). A copy there would be found ahead of the build by every
    new pwsh and by Invoke-DscResource, so this script warns about any copy it finds in
    one of those folders instead of adding to them.

    The change lasts for the current process only. Run the script again in each new
    session, and after each build.

.PARAMETER Version
    Module version folder to use. Defaults to the single version found in the built
    output.
#>
[CmdletBinding()]
param(
    [string] $Version
)

$ErrorActionPreference = 'Stop'

$repoRoot  = Split-Path -Parent $PSScriptRoot
$outputRoot = Join-Path $repoRoot 'output'
$builtModuleRoot = Join-Path $outputRoot 'builtModule'
$builtRoot = Join-Path $builtModuleRoot 'AzureDevOpsDscNative'

if (-not (Test-Path $builtRoot))
{
    throw "[redeploy] Built module not found at '$builtRoot'. Run: .\build.ps1 -Tasks build"
}

if (-not $Version)
{
    $versionDirs = @(Get-ChildItem $builtRoot -Directory)
    if ($versionDirs.Count -ne 1)
    {
        throw "[redeploy] Expected exactly one version under '$builtRoot' but found $($versionDirs.Count). Specify -Version."
    }
    $Version = $versionDirs[0].Name
}

$source = Join-Path $builtRoot $Version
if (-not (Test-Path $source))
{
    throw "[redeploy] Source version path not found: $source"
}
$nestedModules = Join-Path $source 'Modules'

# Drop any earlier entry under ./output - a previous build's version folder, or
# output\RequiredModules, which holds a second DscResource.Common - then put the build first.
$separator = [System.IO.Path]::PathSeparator
$keep = $env:PSModulePath -split [regex]::Escape($separator) | Where-Object {
    $_ -and -not $_.StartsWith($outputRoot, [System.StringComparison]::OrdinalIgnoreCase)
}
$env:PSModulePath = (@($builtModuleRoot, $nestedModules) + $keep | Select-Object -Unique) -join $separator

Write-Host "[redeploy] Using AzureDevOpsDscNative $Version from $source"
Write-Host "[redeploy] PSModulePath for this session now starts with:"
Write-Host "[redeploy]   $builtModuleRoot"
Write-Host "[redeploy]   $nestedModules"

# A copy in a standard module folder is re-added to PSModulePath by every new pwsh,
# so it would be loaded instead of the build. Say so; removing it is left to the user.
$standardRoots = foreach ($base in [Environment]::GetFolderPath('MyDocuments'), $env:ProgramFiles)
{
    if ($base)
    {
        Join-Path $base 'PowerShell\Modules'
        Join-Path $base 'WindowsPowerShell\Modules'
    }
}
foreach ($root in $standardRoots)
{
    foreach ($name in 'AzureDevOpsDscNative', 'AzureDevOpsDsc.Common', 'DscResource.Common')
    {
        $installed = Join-Path $root $name
        if (Test-Path $installed)
        {
            Write-Warning "[redeploy] '$installed' will be loaded instead of the build by new sessions and by Invoke-DscResource. Remove it."
        }
    }
}

# Sanity verification
$projFile = Join-Path $nestedModules 'AzureDevOpsDsc.Common\Resources\Functions\Public\AzDoProject\Get-AzDoProject.ps1'
if (Test-Path $projFile)
{
    $has404 = [bool](Select-String -Path $projFile -Pattern "match '404'" -SimpleMatch)
    Write-Host "[redeploy] Get-AzDoProject 404-catch present: $has404"
}
$markerTotal = (Get-ChildItem (Join-Path $nestedModules 'AzureDevOpsDsc.Common') -Recurse -Filter *.ps1 |
    Select-String 'falling back to live API lookup' -SimpleMatch).Count
Write-Host "[redeploy] live-fallback marker count in built .Common: $markerTotal"
