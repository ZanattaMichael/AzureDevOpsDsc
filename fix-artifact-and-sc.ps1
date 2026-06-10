$root = 'C:\Git\AzureDevOpsDsc'

# Fix 1: ArtifactFeedPermission tests - remove -isInherited parameter too
$afDir = Join-Path $root 'tests\Unit\Modules\AzureDevOpsDsc.Common\Resources\Functions\Public\AzDoArtifactFeedPermission'
Get-ChildItem $afDir -Filter '*.tests.ps1' | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if ($content -match '-isInherited \$false') {
        $new = $content -replace '\s+-isInherited \$false', ''
        Set-Content -Path $_.FullName -Value $new -NoNewline
        Write-Host "Removed -isInherited from: $($_.Name)"
    }
}

# Fix 2: ServiceConnection Get- "when namespace not found" needs a valid project
$scGet = Join-Path $root 'tests\Unit\Modules\AzureDevOpsDsc.Common\Resources\Functions\Public\AzDoServiceConnectionPermission\Get-AzDoServiceConnectionPermission.tests.ps1'
$content = Get-Content $scGet -Raw
$old = @'
    Context "when namespace not found" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith { return $null }
        }
'@
$new = @'
    Context "when namespace not found" {
        BeforeEach {
            Mock -CommandName Get-CacheItem -MockWith {
                param ($Key, $Type)
                if ($Type -eq 'LiveProjects') { return @{ id = 'mock-project-id' } }
                return $null
            }
        }
'@
if ($content -match [regex]::Escape($old.Trim())) {
    $content = $content.Replace($old, $new)
    Set-Content -Path $scGet -Value $content -NoNewline
    Write-Host "Fixed ServiceConnection Get- namespace-not-found context"
} else {
    Write-Host "WARNING: pattern not found in Get-AzDoServiceConnectionPermission.tests.ps1"
    # fallback: show the relevant section
    $content | Select-String 'namespace not found' -Context 0,5 | ForEach-Object { Write-Host $_ }
}
