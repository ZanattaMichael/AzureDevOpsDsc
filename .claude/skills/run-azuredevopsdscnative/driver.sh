#!/usr/bin/env bash
#
# run-azuredevopsdscnative driver
#
# What this does:
#   * Verifies pwsh (installs 7.6.x from Microsoft's repo if missing).
#   * Verifies Pester 5.7.1 is on PSModulePath (side-loads from nuget.org if
#     PowerShell Gallery is blocked - it is, in Claude Code's sandbox).
#   * Runs one of the two unit-test suites, or the full Common suite by
#     default. Reports Passed/Failed/Skipped and exits non-zero on failure.
#
# What this does NOT do:
#   * The `build` task. `./build.ps1 -ResolveDependency -Tasks build` needs
#     PSGallery (Sampler/ModuleBuilder/InvokeBuild), which is proxy-blocked
#     here. See SKILL.md "Build" for what CI does.
#   * The Classes suite (`azuredevopsdsc.tests.ps1`). Its tests parse-time
#     resolve classes via `using module AzureDevOpsDscNative` against the
#     BUILT module - no build, no run. This driver skips it.
#   * Integration tests. They target a live Azure DevOps org and only run
#     on the self-hosted `AZDO-AGENT` runner. See CLAUDE.md.
#
# Usage:
#   ./driver.sh              # runs the full Common suite (~60s, ~1670 tests)
#   ./driver.sh <path>       # runs one test file or subdirectory
#   ./driver.sh --load-only  # dot-sources modules & exits (smoke test)

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
PSMODS_DIR="${PSMODS_DIR:-/root/psmods}"
PESTER_VERSION="5.7.1"

log() { printf '[driver] %s\n' "$*" >&2; }

# --- pwsh ------------------------------------------------------------------
if ! command -v pwsh >/dev/null 2>&1; then
    log "pwsh not found; installing PowerShell 7 from Microsoft's Ubuntu 22.04 repo"
    sudo apt-get update -qq
    sudo apt-get install -y wget apt-transport-https software-properties-common
    wget -q https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O /tmp/pmp.deb
    sudo dpkg -i /tmp/pmp.deb
    sudo apt-get update -qq
    sudo apt-get install -y powershell
fi
log "pwsh: $(pwsh --version)"

# --- Pester (side-load from nuget.org because PSGallery is blocked) --------
if [ ! -f "$PSMODS_DIR/Pester/$PESTER_VERSION/Pester.psd1" ]; then
    log "Pester $PESTER_VERSION not present; downloading from api.nuget.org"
    mkdir -p "$PSMODS_DIR/Pester"
    tmp=$(mktemp -d)
    curl -sSf --max-time 60 \
        "https://api.nuget.org/v3-flatcontainer/pester/$PESTER_VERSION/pester.$PESTER_VERSION.nupkg" \
        -o "$tmp/Pester.nupkg"
    unzip -q "$tmp/Pester.nupkg" -d "$tmp/unpacked"
    # nuget/Chocolatey layout puts the module under tools/; PSModulePath needs it
    # directly under <path>/Pester/<version>/Pester.psd1
    mkdir -p "$PSMODS_DIR/Pester/$PESTER_VERSION"
    cp -r "$tmp/unpacked/tools/." "$PSMODS_DIR/Pester/$PESTER_VERSION/"
    rm -rf "$tmp"
fi
log "Pester side-load path: $PSMODS_DIR/Pester/$PESTER_VERSION"

# --- Args ------------------------------------------------------------------
LOAD_ONLY=0
TEST_PATH="./tests/Unit/Modules/AzureDevOpsDsc.Common"
if [ "${1:-}" = "--load-only" ]; then
    LOAD_ONLY=1
elif [ -n "${1:-}" ]; then
    TEST_PATH="$1"
fi

# --- Invoke pwsh -----------------------------------------------------------
cd "$REPO_ROOT"
export PSMODULEPATH="$PSMODS_DIR:${PSModulePath:-}"

if [ "$LOAD_ONLY" = 1 ]; then
    log "Load-only smoke: dot-sourcing modules"
    pwsh -NoProfile -Command "
        \$env:PSModulePath = '$PSMODS_DIR:' + \$env:PSModulePath
        ./azuredevopsdsc.common.tests.ps1 -LoadModulesOnly
        Write-Host '[driver] LoadModulesOnly OK'
    "
    exit 0
fi

log "Running Pester against: $TEST_PATH"
pwsh -NoProfile -Command "
    \$env:PSModulePath = '$PSMODS_DIR:' + \$env:PSModulePath
    ./azuredevopsdsc.common.tests.ps1 -LoadModulesOnly
    Import-Module Pester -RequiredVersion $PESTER_VERSION -Force

    \$cfg = New-PesterConfiguration
    \$cfg.Run.Path      = '$TEST_PATH'
    \$cfg.Run.PassThru  = \$true
    \$cfg.Output.Verbosity = 'Minimal'
    \$cfg.CodeCoverage.Enabled = \$false

    \$sw = [Diagnostics.Stopwatch]::StartNew()
    \$r  = Invoke-Pester -Configuration \$cfg
    \$sw.Stop()

    Write-Host ''
    Write-Host ('[driver] Passed: {0}  Failed: {1}  Skipped: {2}  Duration: {3}' -f \$r.PassedCount, \$r.FailedCount, \$r.SkippedCount, \$sw.Elapsed)
    if (\$r.FailedCount -gt 0) { exit 1 }
"
