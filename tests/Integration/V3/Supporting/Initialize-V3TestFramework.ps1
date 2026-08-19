#
# V3 test framework initializer.
# Dot-sourced by Invoke-V3Tests.ps1 before any test file runs.
#
# Responsibilities:
#   1. Verify the 'dsc' CLI is on PATH (DSC v3 requirement).
#   2. Load and authenticate the AzureDevOpsDsc module from the build output,
#      so the PowerShell adapter can resolve resources.
#   3. Expose $Global:V3TestOrg for use in test files.
#
param(
    [Parameter(Mandatory)]
    [string]$TestFrameworkConfigurationPath
)

#
# 1 — Verify DSC v3 CLI

$dscCmd = Get-Command dsc -CommandType Application -ErrorAction SilentlyContinue
if (-not $dscCmd)
{
    throw "[Initialize-V3TestFramework] DSC v3 CLI ('dsc') not found on PATH. " +
          "Install from https://github.com/PowerShell/DSC/releases and ensure it is on PATH."
}
$dscVersion = (dsc --version 2>&1) -replace '^v', ''
Write-Host "[V3] DSC CLI version : $dscVersion"

#
# 2 — Load test framework configuration

if (-not (Test-Path $TestFrameworkConfigurationPath))
{
    throw "[Initialize-V3TestFramework] Configuration file not found: $TestFrameworkConfigurationPath"
}

$script:V3Config = Get-Content $TestFrameworkConfigurationPath | ConvertFrom-Json

if (-not $script:V3Config.Organization)
{
    throw "[Initialize-V3TestFramework] 'Organization' field missing from configuration."
}

#
# 3 — Authenticate the module (same as v2 framework)

if ($script:V3Config.AuthenticationType -eq 'PAT')
{
    New-AzDoAuthenticationProvider -OrganizationName $script:V3Config.Organization `
                                   -PersonalAccessToken $script:V3Config.PATToken
}
elseif ($script:V3Config.AuthenticationType -eq 'ManagedIdentity')
{
    New-AzDoAuthenticationProvider -OrganizationName $script:V3Config.Organization `
                                   -useManagedIdentity
}
else
{
    throw "[Initialize-V3TestFramework] Unsupported AuthenticationType: $($script:V3Config.AuthenticationType)"
}

#
# 4 — Expose org name for test files

$Global:V3TestOrg = $script:V3Config.Organization
Write-Host "[V3] Organization    : $Global:V3TestOrg"
Write-Host "[V3] Framework ready."
