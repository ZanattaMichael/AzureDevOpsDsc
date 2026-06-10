$Global:RepositoryRoot = 'C:\Git\AzureDevOpsDsc'
Import-Module -Name (Join-Path $Global:RepositoryRoot 'tests\Unit\Modules\TestHelpers\CommonTestCases.psm1') -Force
Import-Module -Name (Join-Path $Global:RepositoryRoot 'tests\Unit\Modules\TestHelpers\CommonTestHelper.psm1') -Force
Import-Module -Name (Join-Path $Global:RepositoryRoot 'tests\Unit\Modules\TestHelpers\CommonTestFunctions.psm1') -Force

# Run all the previously-failing permission test directories
$dirs = @(
    'AzDoEnvironmentPermission'
    'AzDoServiceConnectionPermission'
    'AzDoVariableGroupPermission'
    'AzDoPipelinePermission'
    'AzDoSecurityNamespacePermission'
    'AzDoGroupPermission'
    'AzDoArtifactFeedPermission'
    'AzDoProjectPermission'
)

foreach ($dir in $dirs) {
    $path = Join-Path $Global:RepositoryRoot "tests\Unit\Modules\AzureDevOpsDsc.Common\Resources\Functions\Public\$dir"
    $r = Invoke-Pester -Path $path -PassThru -Output None
    Write-Host "$dir : Passed=$($r.PassedCount) Failed=$($r.FailedCount)"
    if ($r.FailedCount -gt 0) {
        $r.Failed | ForEach-Object { Write-Host "  FAIL: $($_.ExpandedName) -- $($_.ErrorRecord.Exception.Message)" }
    }
}
