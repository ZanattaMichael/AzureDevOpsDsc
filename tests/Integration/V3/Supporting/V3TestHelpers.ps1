#
# DSC v3 helper functions for integration tests.
# Dot-sourced by Invoke-V3Tests.ps1 and available to all V3 test files.
#
# Requires: DSC v3 CLI ('dsc') on $env:PATH and the AzureDevOpsDsc module
# in $env:PSModulePath (built via build.ps1 and added by the CI workflow).
#

function Assert-DscV3Available
{
    $cmd = Get-Command dsc -CommandType Application -ErrorAction SilentlyContinue
    if (-not $cmd)
    {
        throw "DSC v3 CLI ('dsc') not found on PATH. " +
              "Install from https://github.com/PowerShell/DSC/releases and ensure it is on PATH."
    }
    $ver = (dsc --version 2>&1) -replace '^v', ''
    Write-Host "[V3] DSC CLI version: $ver"
}

function Invoke-DscV3Resource
{
    <#
    .SYNOPSIS
        Thin wrapper around 'dsc resource <method>' using the Microsoft.DSC/PowerShell adapter.

    .PARAMETER ResourceName
        PowerShell DSC class resource name (e.g. AzDoProject).

    .PARAMETER ModuleName
        Module that exports the resource (default: AzureDevOpsDscNative).

    .PARAMETER Method
        Get | Set | Test

    .PARAMETER Property
        Hashtable of resource properties.

    .OUTPUTS
        PSCustomObject — parsed JSON output from the dsc CLI.
    #>
    param(
        [Parameter(Mandatory)][string]$ResourceName,
        [string]$ModuleName  = 'AzureDevOpsDscNative',
        [Parameter(Mandatory)][ValidateSet('Get','Set','Test')][string]$Method,
        [Parameter(Mandatory)][hashtable]$Property
    )

    $payload = @{
        resources = @(
            @{
                name       = "$ResourceName-dscv3-test"
                type       = "$ModuleName/$ResourceName"
                properties = $Property
            }
        )
    } | ConvertTo-Json -Depth 10 -Compress

    # Force JSON on stdout (dsc defaults to YAML) and keep progress/trace on stderr so it
    # never contaminates the parsed document. Redirect stderr to a temp file rather than
    # merging with 2>&1, so a failure can still surface the diagnostic text.
    $dscMethod  = $Method.ToLower()
    $stderrPath = [System.IO.Path]::GetTempFileName()
    try
    {
        $rawOutput  = $payload | dsc --output-format json resource $dscMethod --resource Microsoft.DSC/PowerShell 2>$stderrPath
        $stderrText = (Get-Content -Path $stderrPath -Raw)
    }
    finally
    {
        Remove-Item -Path $stderrPath -Force -ErrorAction SilentlyContinue
    }

    if ($LASTEXITCODE -ne 0)
    {
        throw "dsc resource $Method returned exit code $LASTEXITCODE.`nStderr: $stderrText`nStdout: $rawOutput"
    }

    # With --output-format json the whole of stdout is a single JSON document (possibly
    # pretty-printed across lines), so parse it as one — no line-by-line extraction.
    $jsonText = ($rawOutput -join "`n").Trim()
    if ([string]::IsNullOrWhiteSpace($jsonText))
    {
        throw "dsc resource $Method produced no output.`nStderr: $stderrText"
    }

    return $jsonText | ConvertFrom-Json
}

function Test-DscV3InDesiredState
{
    param(
        [string]$ResourceName,
        [string]$ModuleName = 'AzureDevOpsDscNative',
        [hashtable]$Property
    )

    $result = Invoke-DscV3Resource -ResourceName $ResourceName -ModuleName $ModuleName `
                                   -Method Test -Property $Property

    # DSC v3 test output: { "desiredState": {}, "actualState": {}, "inDesiredState": true }
    # The PowerShell adapter wraps this inside a "results" array from the group resource.
    $testResult = if ($result.results) { $result.results[0] } else { $result }
    return [bool]$testResult.inDesiredState
}
