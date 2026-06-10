$Global:RepositoryRoot = 'C:\Git\AzureDevOpsDsc'
Import-Module -Name (Join-Path $Global:RepositoryRoot 'tests\Unit\Modules\TestHelpers\CommonTestCases.psm1') -Force
Import-Module -Name (Join-Path $Global:RepositoryRoot 'tests\Unit\Modules\TestHelpers\CommonTestHelper.psm1') -Force
Import-Module -Name (Join-Path $Global:RepositoryRoot 'tests\Unit\Modules\TestHelpers\CommonTestFunctions.psm1') -Force

$dirs = @(
    'AzDoArtifactFeed', 'AzDoWiki', 'AzDoProject', 'AzDoNotificationSubscription',
    'AzDoGitRepository', 'AzDoPipelineEnvironment', 'AzDoPipeline', 'AzDoCheckConfiguration', 'AzDoAuditStream'
)
$totalPassed = 0; $totalFailed = 0
foreach ($dir in $dirs) {
    $path = Join-Path $Global:RepositoryRoot "tests\Unit\Modules\AzureDevOpsDsc.Common\Resources\Functions\Public\$dir"
    $r = Invoke-Pester -Path $path -PassThru -Output None
    $totalPassed += $r.PassedCount; $totalFailed += $r.FailedCount
    if ($r.FailedCount -gt 0) {
        Write-Host "$dir : $($r.PassedCount)P $($r.FailedCount)F"
        $r.Failed | ForEach-Object { Write-Host "  FAIL: $($_.ExpandedName): $($_.ErrorRecord.Exception.Message)" }
    } else {
        Write-Host "$dir : $($r.PassedCount)P 0F OK"
    }
}
Write-Host "Total: Passed=$totalPassed  Failed=$totalFailed"
