$RepositoryRoot = 'C:\Git\AzureDevOpsDsc'

$testFiles = Get-ChildItem "$RepositoryRoot\tests\Unit\Modules\AzureDevOpsDsc.Common\Resources" -Filter '*.tests.ps1' -Recurse

$fixed = 0
foreach ($f in $testFiles) {
    $content = Get-Content $f.FullName -Raw

    # Check if Mock Get-AzDoOrganizationName appears before Get-FunctionItem
    $mockPos = $content.IndexOf('Mock -CommandName Get-AzDoOrganizationName')
    $loadPos = $content.IndexOf('Get-FunctionItem')
    if ($mockPos -lt 0 -or $loadPos -lt 0 -or $mockPos -ge $loadPos) { continue }

    # Parse lines
    $lines = $content -split "`r?`n"

    # Find the Mock line index and the Get-FunctionItem loop end index
    $mockLineIdx = -1
    $loadLineStart = -1
    $loadLineEnd = -1
    $inLoadBlock = $false

    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($mockLineIdx -lt 0 -and $lines[$i] -match 'Mock\s+-CommandName\s+Get-AzDoOrganizationName') {
            $mockLineIdx = $i
        }
        if ($loadLineStart -lt 0 -and $lines[$i] -match 'Get-FunctionItem') {
            # The load block is typically:
            #   $files = Get-FunctionItem (Find-MockedFunctions ...)
            #   ForEach ($file in $files) { . $file.FullName }
            $loadLineStart = $i
        }
        if ($loadLineStart -ge 0 -and $loadLineEnd -lt 0 -and $i -gt $loadLineStart) {
            # Look for the ForEach closing brace line
            if ($lines[$i] -match '^\s*\}' -or $lines[$i] -match 'ForEach.*FullName') {
                if ($lines[$i] -match 'ForEach.*FullName') {
                    $loadLineEnd = $i
                } elseif ($i -gt $loadLineStart + 1) {
                    $loadLineEnd = $i
                }
            }
        }
    }

    if ($mockLineIdx -lt 0 -or $loadLineStart -lt 0) { continue }

    # Find the actual end of the ForEach block
    # Pattern: $files = Get-FunctionItem (Find-MockedFunctions...)
    #          ForEach ($file in $files) { . $file.FullName }
    # Could be on same line or next line
    $forEachLineIdx = -1
    for ($i = $loadLineStart; $i -lt [Math]::Min($loadLineStart + 5, $lines.Count); $i++) {
        if ($lines[$i] -match 'ForEach') {
            $forEachLineIdx = $i
            break
        }
    }
    if ($forEachLineIdx -lt 0) { continue }

    # Build new line list: move the Mock line(s) to after the ForEach block
    # Find all consecutive Mock lines starting at mockLineIdx
    $mockLines = @()
    $i = $mockLineIdx
    while ($i -lt $lines.Count -and $lines[$i] -match '^\s*(Mock\s|#)') {
        $mockLines += $lines[$i]
        $i++
    }
    $mockEndIdx = $i - 1

    # Remove mock lines from their current position, insert after forEachLineIdx
    $newLines = [System.Collections.Generic.List[string]]::new()
    for ($j = 0; $j -lt $lines.Count; $j++) {
        if ($j -ge $mockLineIdx -and $j -le $mockEndIdx) {
            # Skip (removing from here)
            continue
        }
        $newLines.Add($lines[$j])
        # After the ForEach line (adjusted for removed lines), insert the mock lines
        if ($j -eq $forEachLineIdx -and $forEachLineIdx -gt $mockEndIdx) {
            foreach ($ml in $mockLines) {
                $newLines.Add($ml)
            }
        }
    }

    $newContent = $newLines -join "`n"
    # Preserve original line ending
    if ($content -match "`r`n") {
        $newContent = $newContent -replace "`n", "`r`n"
    }
    Set-Content -Path $f.FullName -Value $newContent -NoNewline
    $fixed++
    Write-Host "Fixed: $($f.Name)"
}

Write-Host "Total fixed: $fixed"
