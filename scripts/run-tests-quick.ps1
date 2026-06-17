$Global:RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Import-Module -Name (Join-Path $Global:RepositoryRoot 'tests\Unit\Modules\TestHelpers\CommonTestCases.psm1') -Force
Import-Module -Name (Join-Path $Global:RepositoryRoot 'tests\Unit\Modules\TestHelpers\CommonTestHelper.psm1') -Force
Import-Module -Name (Join-Path $Global:RepositoryRoot 'tests\Unit\Modules\TestHelpers\CommonTestFunctions.psm1') -Force

# Run only the permission-related directories that were recently fixed
$dirs = @(
    'tests\Unit\Modules\AzureDevOpsDsc.Common\Resources\Functions\Public\AzDoAgentPoolPermission'
    'tests\Unit\Modules\AzureDevOpsDsc.Common\Resources\Functions\Public\AzDoArtifactFeedPermission'
    'tests\Unit\Modules\AzureDevOpsDsc.Common\Resources\Functions\Public\AzDoEnvironmentPermission'
    'tests\Unit\Modules\AzureDevOpsDsc.Common\Resources\Functions\Public\AzDoGroupPermission'
    'tests\Unit\Modules\AzureDevOpsDsc.Common\Resources\Functions\Public\AzDoPipelinePermission'
    'tests\Unit\Modules\AzureDevOpsDsc.Common\Resources\Functions\Public\AzDoProjectPermission'
    'tests\Unit\Modules\AzureDevOpsDsc.Common\Resources\Functions\Public\AzDoSecurityNamespacePermission'
    'tests\Unit\Modules\AzureDevOpsDsc.Common\Resources\Functions\Public\AzDoServiceConnectionPermission'
    'tests\Unit\Modules\AzureDevOpsDsc.Common\Resources\Functions\Public\AzDoVariableGroupPermission'
    'tests\Unit\Modules\AzureDevOpsDsc.Common\Api\Functions\Private\Cache'
    'tests\Unit\Modules\AzureDevOpsDsc.Common\Api\Functions\Private\Helper\ACL'
)

$totalPassed = 0; $totalFailed = 0
foreach ($dir in $dirs) {
    $path = Join-Path $Global:RepositoryRoot $dir
    $r = Invoke-Pester -Path $path -PassThru -Output None
    $totalPassed += $r.PassedCount
    $totalFailed += $r.FailedCount
    if ($r.FailedCount -gt 0) {
        Write-Host "FAIL in $([System.IO.Path]::GetFileName($dir)): $($r.FailedCount) failures"
        $r.Failed | ForEach-Object { Write-Host "  - $($_.ExpandedName): $($_.ErrorRecord.Exception.Message)" }
    }
}
Write-Host "Quick check: Passed=$totalPassed  Failed=$totalFailed"
