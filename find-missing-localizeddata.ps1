$testRoot = 'C:\Git\AzureDevOpsDsc\tests\Unit\Modules\AzureDevOpsDsc.Common\Resources\Functions\Public'
$srcRoot  = 'C:\Git\AzureDevOpsDsc\source\Modules\AzureDevOpsDsc.Common\Resources\Functions\Public'

Get-ChildItem $testRoot -Recurse -Filter '*.tests.ps1' | Where-Object {
    $name = $_.Name
    if ($name -notmatch '^(New|Set|Remove)-') { return $false }

    $content = Get-Content $_.FullName -Raw
    if ($content -match '002\.LocalizedDataAzSerializationPatten') { return $false }

    # Check if the corresponding source file uses LocalizedDataAzSerializationPatten
    $relPath = $_.FullName.Substring($testRoot.Length).TrimStart('\')
    $srcFile  = Join-Path $srcRoot ($relPath -replace '\.tests\.ps1$', '.ps1')
    if (-not (Test-Path $srcFile)) { return $false }

    $srcContent = Get-Content $srcFile -Raw
    return $srcContent -match 'LocalizedDataAzSerializationPatten'
} | Select-Object -ExpandProperty FullName
