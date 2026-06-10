$Global:RepositoryRoot = 'C:\Git\AzureDevOpsDsc'
Import-Module -Name (Join-Path $Global:RepositoryRoot 'tests\Unit\Modules\TestHelpers\CommonTestCases.psm1')
Import-Module -Name (Join-Path $Global:RepositoryRoot 'tests\Unit\Modules\TestHelpers\CommonTestHelper.psm1')
Import-Module -Name (Join-Path $Global:RepositoryRoot 'tests\Unit\Modules\TestHelpers\CommonTestFunctions.psm1')

$r = Invoke-Pester -Path (Join-Path $Global:RepositoryRoot 'tests\Unit\Modules\AzureDevOpsDsc.Common') -PassThru -Output None
Write-Host "Passed: $($r.PassedCount)  Failed: $($r.FailedCount)  Skipped: $($r.SkippedCount)"
$r.Failed | Group-Object { ($_.Path | Select-Object -Last 1) -replace ' > .*','' } | Sort-Object Count -Descending | Select-Object -First 25 | Format-Table Count, Name -AutoSize
