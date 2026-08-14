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
        Module that exports the resource (default: AzureDevOpsDsc).

    .PARAMETER Method
        Get | Set | Test

    .PARAMETER Property
        Hashtable of resource properties.

    .OUTPUTS
        PSCustomObject — parsed JSON output from the dsc CLI.
    #>
    param(
        [Parameter(Mandatory)][string]$ResourceName,
        [string]$ModuleName  = 'AzureDevOpsDsc',
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

    $rawOutput = switch ($Method)
    {
        'Get'  { $payload | dsc resource get  --resource Microsoft.DSC/PowerShell 2>&1 }
        'Set'  { $payload | dsc resource set  --resource Microsoft.DSC/PowerShell 2>&1 }
        'Test' { $payload | dsc resource test --resource Microsoft.DSC/PowerShell 2>&1 }
    }

    if ($LASTEXITCODE -ne 0)
    {
        throw "dsc resource $Method returned exit code $LASTEXITCODE.`nOutput: $rawOutput"
    }

    # dsc may emit progress lines before the JSON block — extract the last JSON object.
    $jsonLines = $rawOutput | Where-Object { $_ -match '^\s*\{' }
    if (-not $jsonLines)
    {
        throw "dsc resource $Method produced no JSON output.`nRaw: $rawOutput"
    }

    return ($jsonLines | Select-Object -Last 1) | ConvertFrom-Json
}

function Test-DscV3InDesiredState
{
    param(
        [string]$ResourceName,
        [string]$ModuleName = 'AzureDevOpsDsc',
        [hashtable]$Property
    )

    $result = Invoke-DscV3Resource -ResourceName $ResourceName -ModuleName $ModuleName `
                                   -Method Test -Property $Property

    # DSC v3 test output: { "desiredState": {}, "actualState": {}, "inDesiredState": true }
    # The PowerShell adapter wraps this inside a "results" array from the group resource.
    $testResult = if ($result.results) { $result.results[0] } else { $result }
    return [bool]$testResult.inDesiredState
}
