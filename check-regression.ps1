$Global:RepositoryRoot = 'C:\Git\AzureDevOpsDsc'
Import-Module -Name (Join-Path $Global:RepositoryRoot 'tests\Unit\Modules\TestHelpers\CommonTestCases.psm1')
Import-Module -Name (Join-Path $Global:RepositoryRoot 'tests\Unit\Modules\TestHelpers\CommonTestHelper.psm1')
Import-Module -Name (Join-Path $Global:RepositoryRoot 'tests\Unit\Modules\TestHelpers\CommonTestFunctions.psm1')

# Run just the AgentPool permission tests
$r = Invoke-Pester -Path (Join-Path $Global:RepositoryRoot 'tests\Unit\Modules\AzureDevOpsDsc.Common\Resources\Functions\Public\AzDoAgentPoolPermission') -PassThru -Output Detailed 2>&1
$r.Failed | ForEach-Object {
    Write-Host "=== FAIL: $($_.ExpandedName) ==="
    Write-Host "Message: $($_.ErrorRecord.Exception.Message)"
    Write-Host "---"
}
