$root = 'C:\Git\AzureDevOpsDsc'

# Fix 1: ServiceConnection tests - replace -ServiceConnectionName with -ConnectionName
$scDir = Join-Path $root 'tests\Unit\Modules\AzureDevOpsDsc.Common\Resources\Functions\Public\AzDoServiceConnectionPermission'
Get-ChildItem $scDir -Filter '*.tests.ps1' | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if ($content -match 'ServiceConnectionName') {
        $new = $content -replace '-ServiceConnectionName ', '-ConnectionName '
        Set-Content -Path $_.FullName -Value $new -NoNewline
        Write-Host "Fixed ServiceConnectionName -> ConnectionName in: $($_.Name)"
    }
}

# Fix 2: ArtifactFeedPermission tests - remove -GroupName parameter (source has no GroupName)
$afDir = Join-Path $root 'tests\Unit\Modules\AzureDevOpsDsc.Common\Resources\Functions\Public\AzDoArtifactFeedPermission'
# First let's see which files have GroupName
Get-ChildItem $afDir -Filter '*.tests.ps1' | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if ($content -match "-GroupName 'TestGroup'") {
        $new = $content -replace "\s+-GroupName 'TestGroup'", ''
        Set-Content -Path $_.FullName -Value $new -NoNewline
        Write-Host "Removed -GroupName from: $($_.Name)"
    }
}
