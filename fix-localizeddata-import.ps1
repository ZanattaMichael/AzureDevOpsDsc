$files = @(
    'tests\Unit\Modules\AzureDevOpsDsc.Common\Resources\Functions\Public\AzDoAgentPoolPermission\New-AzDoAgentPoolPermission.tests.ps1'
    'tests\Unit\Modules\AzureDevOpsDsc.Common\Resources\Functions\Public\AzDoAgentPoolPermission\Set-AzDoAgentPoolPermission.tests.ps1'
    'tests\Unit\Modules\AzureDevOpsDsc.Common\Resources\Functions\Public\AzDoArtifactFeedPermission\New-AzDoArtifactFeedPermission.tests.ps1'
    'tests\Unit\Modules\AzureDevOpsDsc.Common\Resources\Functions\Public\AzDoArtifactFeedPermission\Set-AzDoArtifactFeedPermission.tests.ps1'
    'tests\Unit\Modules\AzureDevOpsDsc.Common\Resources\Functions\Public\AzDoEnvironmentPermission\New-AzDoEnvironmentPermission.tests.ps1'
    'tests\Unit\Modules\AzureDevOpsDsc.Common\Resources\Functions\Public\AzDoEnvironmentPermission\Set-AzDoEnvironmentPermission.tests.ps1'
    'tests\Unit\Modules\AzureDevOpsDsc.Common\Resources\Functions\Public\AzDoGroupPermission\New-AzDoGroupPermission.tests.ps1'
    'tests\Unit\Modules\AzureDevOpsDsc.Common\Resources\Functions\Public\AzDoGroupPermission\Set-AzDoGroupPermission.tests.ps1'
    'tests\Unit\Modules\AzureDevOpsDsc.Common\Resources\Functions\Public\AzDoPipelinePermission\New-AzDoPipelinePermission.tests.ps1'
    'tests\Unit\Modules\AzureDevOpsDsc.Common\Resources\Functions\Public\AzDoPipelinePermission\Set-AzDoPipelinePermission.tests.ps1'
    'tests\Unit\Modules\AzureDevOpsDsc.Common\Resources\Functions\Public\AzDoProjectPermission\Set-AzDoProjectPermission.tests.ps1'
    'tests\Unit\Modules\AzureDevOpsDsc.Common\Resources\Functions\Public\AzDoSecurityNamespacePermission\New-AzDoSecurityNamespacePermission.tests.ps1'
    'tests\Unit\Modules\AzureDevOpsDsc.Common\Resources\Functions\Public\AzDoSecurityNamespacePermission\Set-AzDoSecurityNamespacePermission.tests.ps1'
    'tests\Unit\Modules\AzureDevOpsDsc.Common\Resources\Functions\Public\AzDoServiceConnectionPermission\New-AzDoServiceConnectionPermission.tests.ps1'
    'tests\Unit\Modules\AzureDevOpsDsc.Common\Resources\Functions\Public\AzDoServiceConnectionPermission\Set-AzDoServiceConnectionPermission.tests.ps1'
    'tests\Unit\Modules\AzureDevOpsDsc.Common\Resources\Functions\Public\AzDoVariableGroupPermission\New-AzDoVariableGroupPermission.tests.ps1'
    'tests\Unit\Modules\AzureDevOpsDsc.Common\Resources\Functions\Public\AzDoVariableGroupPermission\Set-AzDoVariableGroupPermission.tests.ps1'
)

$root = 'C:\Git\AzureDevOpsDsc'
$insertLine = "        . (Get-ClassFilePath '002.LocalizedDataAzSerializationPatten')"

foreach ($rel in $files) {
    $path = Join-Path $root $rel
    $content = Get-Content $path -Raw

    # Try inserting after the Ensure ClassFilePath line
    $pattern = "(        \. \(Get-ClassFilePath 'Ensure'\))"
    if ($content -match $pattern) {
        $new = $content -replace $pattern, "`$1`n$insertLine"
        Set-Content -Path $path -Value $new -NoNewline
        Write-Host "Fixed (Ensure pattern): $rel"
    }
    # Fallback: insert after Get-AzDoCacheObjects or 000.CacheItem
    elseif ($content -match "(        \. \(Get-FunctionItem 'Get-AzDoCacheObjects\.ps1'\))") {
        $new = $content -replace "(        \. \(Get-FunctionItem 'Get-AzDoCacheObjects\.ps1'\))", "$insertLine`n`$1"
        Set-Content -Path $path -Value $new -NoNewline
        Write-Host "Fixed (CacheObjects pattern): $rel"
    }
    else {
        Write-Host "WARNING: no insert point found in $rel"
        # Show what class loads are present
        $content | Select-String 'Get-ClassFilePath|Get-FunctionItem' | ForEach-Object { Write-Host "  $_" }
    }
}
