$Global:RepositoryRoot = 'C:\Git\AzureDevOpsDsc'
Import-Module -Name (Join-Path $Global:RepositoryRoot 'tests\Unit\Modules\TestHelpers\CommonTestCases.psm1') -Force
Import-Module -Name (Join-Path $Global:RepositoryRoot 'tests\Unit\Modules\TestHelpers\CommonTestHelper.psm1') -Force
Import-Module -Name (Join-Path $Global:RepositoryRoot 'tests\Unit\Modules\TestHelpers\CommonTestFunctions.psm1') -Force

$testRoot = Join-Path $Global:RepositoryRoot 'tests\Unit\Modules\AzureDevOpsDsc.Common'
$dirs = Get-ChildItem $testRoot -Directory | Sort-Object Name

$totalPassed = 0; $totalFailed = 0

foreach ($dir in $dirs) {
    Write-Host "Running: $($dir.Name) ..."
    $r = Invoke-Pester -Path $dir.FullName -PassThru -Output None
    $totalPassed += $r.PassedCount; $totalFailed += $r.FailedCount
    Write-Host "  -> $($r.PassedCount) passed, $($r.FailedCount) failed"
}

Write-Host "TOTAL: Passed=$totalPassed  Failed=$totalFailed"
