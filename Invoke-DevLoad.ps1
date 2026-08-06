<#
.SYNOPSIS
    Loads AzureDevOpsDsc from source into the current session for interactive testing.

.DESCRIPTION
    Bootstraps the module without a full build by dot-sourcing all enums, classes,
    and function files from the source tree in dependency order. Sets required
    environment variables and global state used by the module and test helpers.

    Run this script in your PowerShell 7 session, then use New-AzDoAuthenticationProvider
    and other public functions interactively, or run the Pester test suites.

.PARAMETER CacheDirectory
    Directory used by the module for file-based caching (ModuleSettings.clixml, etc.).
    Defaults to $env:TEMP/AzureDevOpsDscCache if $ENV:AZDODSC_CACHE_DIRECTORY is not set.

.PARAMETER RunClassTests
    After loading, run the Classes unit test suite via azuredevopsdsc.tests.ps1.

.PARAMETER RunCommonTests
    After loading, run the AzureDevOpsDsc.Common unit test suite via azuredevopsdsc.common.tests.ps1.

.PARAMETER RunAllTests
    After loading, run both unit test suites.

.EXAMPLE
    # Load the module for interactive use
    . ./Invoke-DevLoad.ps1

.EXAMPLE
    # Load and run all unit tests
    . ./Invoke-DevLoad.ps1 -RunAllTests

.EXAMPLE
    # Custom cache directory
    . ./Invoke-DevLoad.ps1 -CacheDirectory /tmp/my-azdo-cache

.NOTES
    Requirements:
      - PowerShell 7.0 or higher  (pwsh)
      - Pester 5.x  (auto-installed to CurrentUser scope when a -Run* switch is used)

    ENVIRONMENT VARIABLES (set before calling New-AzDoAuthenticationProvider):

      AZDODSC_CACHE_DIRECTORY  (required by the DSC resource engine; set automatically here)

      Optional logging:
        AZDO_WARNINGLOGGING_FILEPATH   path for warning log file
        AZDO_ERRORLOGGING_FILEPATH     path for error log file

    AUTHENTICATION METHODS:
      PAT          : -PersonalAccessToken "<pat>"
      Managed ID   : -useManagedIdentity
      Service Prin : -TenantId -ClientId -ClientSecret
      Certificate  : -TenantId -ClientId (-CertificateThumbprint | -CertificatePath + -CertificatePassword)
      Azure CLI    : -useAzureCLI  (requires az login)
#>

[CmdletBinding()]
param (
    [Parameter()]
    [string]$CacheDirectory,

    [Parameter()]
    [switch]$RunClassTests,

    [Parameter()]
    [switch]$RunCommonTests,

    [Parameter()]
    [switch]$RunAllTests
)

Set-StrictMode -Off
$ErrorActionPreference = 'Stop'

# ─────────────────────────────────────────────────────────────────────────────
# 1.  Pre-flight
# ─────────────────────────────────────────────────────────────────────────────

if ($PSVersionTable.PSVersion.Major -lt 7)
{
    throw "AzureDevOpsDsc requires PowerShell 7.0+. Current: $($PSVersionTable.PSVersion). " +
          "Install from https://aka.ms/powershell"
}

Write-Host ''
Write-Host '=======================================' -ForegroundColor Cyan
Write-Host '  AzureDevOpsDsc  Dev Loader' -ForegroundColor Cyan
Write-Host "  PowerShell $($PSVersionTable.PSVersion)  |  $([System.Runtime.InteropServices.RuntimeInformation]::OSDescription)" -ForegroundColor Cyan
Write-Host '=======================================' -ForegroundColor Cyan
Write-Host ''

# ─────────────────────────────────────────────────────────────────────────────
# 2.  Resolve key paths
# ─────────────────────────────────────────────────────────────────────────────

$RepoRoot      = $PSScriptRoot
$SourceRoot    = Join-Path $RepoRoot 'source'
$CommonRoot    = Join-Path $SourceRoot 'Modules' 'AzureDevOpsDsc.Common'
$TestHelperDir = Join-Path $RepoRoot 'tests' 'Unit' 'Modules' 'TestHelpers'

Write-Host "Repo   : $RepoRoot" -ForegroundColor DarkGray
Write-Host "Source : $SourceRoot" -ForegroundColor DarkGray

# ─────────────────────────────────────────────────────────────────────────────
# 3.  Environment variables required by the module
# ─────────────────────────────────────────────────────────────────────────────

if ($CacheDirectory)
{
    $ENV:AZDODSC_CACHE_DIRECTORY = $CacheDirectory
}
elseif (-not $ENV:AZDODSC_CACHE_DIRECTORY)
{
    $ENV:AZDODSC_CACHE_DIRECTORY = Join-Path ([System.IO.Path]::GetTempPath()) 'AzureDevOpsDscCache'
}

if (-not (Test-Path -Path $ENV:AZDODSC_CACHE_DIRECTORY))
{
    $null = New-Item -Path $ENV:AZDODSC_CACHE_DIRECTORY -ItemType Directory -Force
}

Write-Host "Cache  : $ENV:AZDODSC_CACHE_DIRECTORY" -ForegroundColor DarkGray
Write-Host ''

# ─────────────────────────────────────────────────────────────────────────────
# 4.  Global state expected by test helpers and base classes
# ─────────────────────────────────────────────────────────────────────────────

Remove-Variable -Name RepositoryRoot -Scope Global -ErrorAction SilentlyContinue
Remove-Variable -Name TestPaths      -Scope Global -ErrorAction SilentlyContinue
Remove-Variable -Name ClassesLoaded  -Scope Global -ErrorAction SilentlyContinue

$Global:RepositoryRoot = $RepoRoot
$Global:ClassesLoaded  = $true

Write-Host 'Indexing source files...' -ForegroundColor Yellow
$Global:TestPaths = Get-ChildItem -LiteralPath $RepoRoot -Recurse -File -Include '*.ps1' |
    Where-Object {
        $_.FullName -notlike '*Tests.ps1' -and
        $_.FullName -notlike '*/output/*' -and
        $_.FullName -notlike '*/tests/*'  -and
        $_.FullName -notlike '*\output\*' -and
        $_.FullName -notlike '*\tests\*'
    }
Write-Host "  $($Global:TestPaths.Count) source files indexed" -ForegroundColor DarkGray
Write-Host ''

# ─────────────────────────────────────────────────────────────────────────────
# 5.  Test helper functions  (Get-FunctionItem, Find-MockedFunctions, etc.)
# ─────────────────────────────────────────────────────────────────────────────

Write-Host 'Loading test helpers...' -ForegroundColor Yellow
Import-Module -Name (Join-Path $TestHelperDir 'CommonTestFunctions.psm1') -Force
Write-Host '  OK: CommonTestFunctions.psm1' -ForegroundColor DarkGray
Write-Host ''

# ─────────────────────────────────────────────────────────────────────────────
# 6.  Enums
# ─────────────────────────────────────────────────────────────────────────────

Write-Host 'Loading enums...' -ForegroundColor Yellow
$enumFiles = Get-ChildItem -LiteralPath (Join-Path $SourceRoot 'Enum') -File -Filter '*.ps1' |
    Sort-Object Name
foreach ($f in $enumFiles)
{
    Write-Verbose "  . $($f.Name)"
    . $f.FullName
}
Write-Host "  $($enumFiles.Count) enum file(s)" -ForegroundColor DarkGray
Write-Host ''

# ─────────────────────────────────────────────────────────────────────────────
# 7.  Classes
#     [DscResource()] is stripped so classes load without a DSC configuration
#     block.  Files are sorted by name so parent classes (lower numbers) load
#     before children.
# ─────────────────────────────────────────────────────────────────────────────

Write-Host 'Loading classes...' -ForegroundColor Yellow
$classFiles = Get-ChildItem -LiteralPath (Join-Path $SourceRoot 'Classes') -File -Filter '*.ps1' |
    Sort-Object Name
foreach ($f in $classFiles)
{
    Write-Verbose "  . $($f.Name)"
    $raw = Get-Content -Path $f.FullName -Raw
    $raw = $raw -replace '\[DscResource\(\)\]', ''
    . ([ScriptBlock]::Create($raw))
}
Write-Host "  $($classFiles.Count) class file(s)" -ForegroundColor DarkGray
Write-Host ''

# ─────────────────────────────────────────────────────────────────────────────
# 8.  AzureDevOpsDsc.Common functions
#     Load order mirrors the dependency chain in AzureDevOpsDsc.Common.psm1.
#
#     IMPORTANT: dot-sourcing MUST happen at script scope (not inside a helper
#     function) so that defined functions persist after each block completes.
#     A foreach loop at script level runs in the current scope; a function body
#     does not — definitions would be lost on return.
# ─────────────────────────────────────────────────────────────────────────────

Write-Host 'Loading AzureDevOpsDsc.Common functions...' -ForegroundColor Yellow

$priv = Join-Path $CommonRoot 'Api' 'Functions' 'Private'

$_sections = [ordered]@{
    'LocalizedData'              = Join-Path $CommonRoot 'LocalizedData'
    'Api\Classes'                = Join-Path $CommonRoot 'Api' 'Classes'
    'Api\Private\Helper'         = Join-Path $priv 'Helper'
    'Api\Private\Authentication' = Join-Path $priv 'Authentication'
    'Api\Private\Cache'          = Join-Path $priv 'Cache'
    'Api\Private\Api'            = Join-Path $priv 'Api'
    'Api\Private\Command'        = Join-Path $priv 'Command'
    'Connection\Private'         = Join-Path $CommonRoot 'Connection' 'Functions' 'Private'
    'Resources\Private'          = Join-Path $CommonRoot 'Resources' 'Functions' 'Private'
    'Resources\Public'           = Join-Path $CommonRoot 'Resources' 'Functions' 'Public'
    'Services\Public'            = Join-Path $CommonRoot 'Services' 'Functions' 'Public'
}

$totalFunctions = 0
foreach ($_label in $_sections.Keys)
{
    $_sectionPath = $_sections[$_label]
    if (-not (Test-Path -LiteralPath $_sectionPath))
    {
        Write-Host "  SKIP (not found): $_label" -ForegroundColor DarkYellow
        continue
    }

    $_sectionFiles = Get-ChildItem -LiteralPath $_sectionPath -Recurse -Filter '*.ps1' | Sort-Object FullName
    foreach ($_f in $_sectionFiles)
    {
        Write-Verbose "  . $($_f.FullName)"
        . $_f.FullName
    }
    Write-Host ("  {0,3} file(s)  [{1}]" -f $_sectionFiles.Count, $_label) -ForegroundColor DarkGray
    $totalFunctions += $_sectionFiles.Count
}

Write-Host ''
Write-Host "  $totalFunctions function file(s) loaded" -ForegroundColor DarkGray
Write-Host ''

# ─────────────────────────────────────────────────────────────────────────────
# 9.  Smoke checks
# ─────────────────────────────────────────────────────────────────────────────

Write-Host 'Verifying load...' -ForegroundColor Yellow

$checks = [ordered]@{
    'TokenType enum'                          = { [TokenType]::PersonalAccessToken -ne $null }
    'TokenType::ServicePrincipal'             = { [TokenType]::ServicePrincipal    -ne $null }
    'TokenType::Certificate'                  = { [TokenType]::Certificate         -ne $null }
    'TokenType::AzureCLI'                     = { [TokenType]::AzureCLI            -ne $null }
    'AuthenticationToken class'               = { [AuthenticationToken]      -ne $null }
    'PersonalAccessToken class'               = { [PersonalAccessToken]      -ne $null }
    'ManagedIdentityToken class'              = { [ManagedIdentityToken]     -ne $null }
    'ServicePrincipalToken class'             = { [ServicePrincipalToken]    -ne $null }
    'CertificateToken class'                  = { [CertificateToken]         -ne $null }
    'AzureCliToken class'                     = { [AzureCliToken]            -ne $null }
    'New-AzDoAuthenticationProvider'          = { $null -ne (Get-Command New-AzDoAuthenticationProvider          -EA SilentlyContinue) }
    'Get-AzServicePrincipalToken'             = { $null -ne (Get-Command Get-AzServicePrincipalToken             -EA SilentlyContinue) }
    'Get-AzServicePrincipalCertificateToken'  = { $null -ne (Get-Command Get-AzServicePrincipalCertificateToken  -EA SilentlyContinue) }
    'Get-AzCliToken'                          = { $null -ne (Get-Command Get-AzCliToken                          -EA SilentlyContinue) }
    'Build-JWTAssertion'                      = { $null -ne (Get-Command Build-JWTAssertion                      -EA SilentlyContinue) }
    'Add-AuthenticationHTTPHeader'            = { $null -ne (Get-Command Add-AuthenticationHTTPHeader            -EA SilentlyContinue) }
    'Test-AzToken'                            = { $null -ne (Get-Command Test-AzToken                            -EA SilentlyContinue) }
    'AZDODSC_CACHE_DIRECTORY set'             = { -not [String]::IsNullOrEmpty($ENV:AZDODSC_CACHE_DIRECTORY) }
    'Cache directory exists'                  = { Test-Path -Path $ENV:AZDODSC_CACHE_DIRECTORY }
}

$pass = 0; $fail = 0
foreach ($label in $checks.Keys)
{
    try
    {
        if (& $checks[$label])
        {
            Write-Host "  [PASS] $label" -ForegroundColor Green
            $pass++
        }
        else
        {
            Write-Host "  [FAIL] $label" -ForegroundColor Red
            $fail++
        }
    }
    catch
    {
        Write-Host "  [FAIL] $label  --  $_" -ForegroundColor Red
        $fail++
    }
}

Write-Host ''
if ($fail -eq 0)
{
    Write-Host "All $pass checks passed. Module is ready." -ForegroundColor Green
}
else
{
    Write-Warning "$fail of $($pass + $fail) checks failed."
}

# ─────────────────────────────────────────────────────────────────────────────
# 10. Usage reference
# ─────────────────────────────────────────────────────────────────────────────

Write-Host ''
Write-Host '─────────────────────────────────────────────────────' -ForegroundColor DarkGray
Write-Host '  Authentication — Quick Reference' -ForegroundColor Cyan
Write-Host '─────────────────────────────────────────────────────' -ForegroundColor DarkGray
@'

  # Personal Access Token
  New-AzDoAuthenticationProvider -OrganizationName "<org>" -PersonalAccessToken "<pat>"

  # Managed Identity  (Azure VM / Arc-enabled machine)
  New-AzDoAuthenticationProvider -OrganizationName "<org>" -useManagedIdentity

  # Service Principal — Client Secret
  New-AzDoAuthenticationProvider -OrganizationName "<org>" `
      -TenantId "<tenant-id>" -ClientId "<client-id>" -ClientSecret "<secret>"

  # Service Principal — Certificate (Windows cert store)
  New-AzDoAuthenticationProvider -OrganizationName "<org>" `
      -TenantId "<tenant-id>" -ClientId "<client-id>" `
      -CertificateThumbprint "<thumbprint>"

  # Service Principal — Certificate (PFX file, cross-platform)
  $pwd = Read-Host "PFX password" -AsSecureString
  New-AzDoAuthenticationProvider -OrganizationName "<org>" `
      -TenantId "<tenant-id>" -ClientId "<client-id>" `
      -CertificatePath "/path/to/cert.pfx" -CertificatePassword $pwd

  # Azure CLI  (requires: az login)
  New-AzDoAuthenticationProvider -OrganizationName "<org>" -useAzureCLI

  # After authenticating:
  $Global:DSCAZDO_AuthenticationToken          # inspect the token object
  Add-AuthenticationHTTPHeader                 # returns the Authorization header value
  Test-AzToken $Global:DSCAZDO_AuthenticationToken

'@ | Write-Host -ForegroundColor White

Write-Host '─────────────────────────────────────────────────────' -ForegroundColor DarkGray
Write-Host '  Globals and environment' -ForegroundColor Cyan
Write-Host '─────────────────────────────────────────────────────' -ForegroundColor DarkGray
Write-Host "  `$Global:DSCAZDO_AuthenticationToken   # current token object" -ForegroundColor White
Write-Host "  `$Global:DSCAZDO_OrganizationName      # current org name" -ForegroundColor White
Write-Host "  `$ENV:AZDODSC_CACHE_DIRECTORY          # $ENV:AZDODSC_CACHE_DIRECTORY" -ForegroundColor White

Write-Host ''
Write-Host '─────────────────────────────────────────────────────' -ForegroundColor DarkGray
Write-Host '  Unit tests' -ForegroundColor Cyan
Write-Host '─────────────────────────────────────────────────────' -ForegroundColor DarkGray
@'
  . ./Invoke-DevLoad.ps1 -RunClassTests    # Classes unit tests
  . ./Invoke-DevLoad.ps1 -RunCommonTests   # AzureDevOpsDsc.Common unit tests
  . ./Invoke-DevLoad.ps1 -RunAllTests      # Both suites

'@ | Write-Host -ForegroundColor White

# ─────────────────────────────────────────────────────────────────────────────
# 11. Optionally run unit tests
# ─────────────────────────────────────────────────────────────────────────────

if (-not ($RunClassTests -or $RunCommonTests -or $RunAllTests))
{
    return
}

$pester = Get-Module -ListAvailable -Name Pester | Where-Object { $_.Version -ge [version]'5.0' }
if (-not $pester)
{
    Write-Host 'Pester 5.x not found — installing to CurrentUser scope...' -ForegroundColor Yellow
    Install-Module -Name Pester -MinimumVersion '5.0' -Force -Scope CurrentUser -SkipPublisherCheck
}
Import-Module Pester -MinimumVersion '5.0' -Force

Write-Host ''
Write-Host '═══════════════════════════════════════════════════' -ForegroundColor Cyan
Write-Host '  Running Unit Tests' -ForegroundColor Cyan
Write-Host '═══════════════════════════════════════════════════' -ForegroundColor Cyan

if ($RunClassTests -or $RunAllTests)
{
    Write-Host ''
    Write-Host '► Class tests  (tests/Unit/Classes)' -ForegroundColor Yellow
    & (Join-Path $RepoRoot 'azuredevopsdsc.tests.ps1')
}

if ($RunCommonTests -or $RunAllTests)
{
    Write-Host ''
    Write-Host '► Common module tests  (tests/Unit/Modules/AzureDevOpsDsc.Common)' -ForegroundColor Yellow
    Import-Module -Name (Join-Path $TestHelperDir 'CommonTestCases.psm1')  -Force
    Import-Module -Name (Join-Path $TestHelperDir 'CommonTestHelper.psm1') -Force
    & (Join-Path $RepoRoot 'azuredevopsdsc.common.tests.ps1')
}
