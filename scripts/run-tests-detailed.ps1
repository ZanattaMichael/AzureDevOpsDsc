$Global:RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Import-Module -Name (Join-Path $Global:RepositoryRoot 'tests\Unit\Modules\TestHelpers\CommonTestCases.psm1')
Import-Module -Name (Join-Path $Global:RepositoryRoot 'tests\Unit\Modules\TestHelpers\CommonTestHelper.psm1')
Import-Module -Name (Join-Path $Global:RepositoryRoot 'tests\Unit\Modules\TestHelpers\CommonTestFunctions.psm1')

$r = Invoke-Pester -Path (Join-Path $Global:RepositoryRoot 'tests\Unit\Modules\AzureDevOpsDsc.Common') -PassThru -Output None
Write-Host "Passed: $($r.PassedCount)  Failed: $($r.FailedCount)  Skipped: $($r.SkippedCount)"

# Show all failures with test names
$r.Failed | ForEach-Object {
    $path = $_.Path -join ' > '
    Write-Host "FAIL: $path"
} | Out-String | Set-Content 'C:\Git\AzureDevOpsDsc\failures.txt'
Write-Host "Failures written to failures.txt"
