$Global:RepositoryRoot = 'C:\Git\AzureDevOpsDsc'
Import-Module -Name (Join-Path $Global:RepositoryRoot 'tests\Unit\Modules\TestHelpers\CommonTestCases.psm1') -Force
Import-Module -Name (Join-Path $Global:RepositoryRoot 'tests\Unit\Modules\TestHelpers\CommonTestHelper.psm1') -Force
Import-Module -Name (Join-Path $Global:RepositoryRoot 'tests\Unit\Modules\TestHelpers\CommonTestFunctions.psm1') -Force

$r = Invoke-Pester -Path (Join-Path $Global:RepositoryRoot 'tests\Unit\Modules\AzureDevOpsDsc.Common\Api') -PassThru -Output None
Write-Host "API Tests: Passed=$($r.PassedCount) Failed=$($r.FailedCount)"
$r.Failed | ForEach-Object {
    Write-Host "FAIL: $($_.Path -join ' > ')"
    Write-Host "  MSG: $($_.ErrorRecord.Exception.Message)"
}
