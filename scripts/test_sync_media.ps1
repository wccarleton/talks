# Test the orchestration with mocked conda/rclone; no network or real uploads.
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$cache = Join-Path $repoRoot '.media-cache'
New-Item -ItemType Directory -Force -Path $cache | Out-Null
$fixture = Join-Path $cache ('sync-test-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path (Join-Path $fixture 'scripts'), (Join-Path $fixture 'images') | Out-Null
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'sync-media.ps1') -Destination (Join-Path $fixture 'scripts/sync-media.ps1')
$mockRclone = Join-Path $fixture 'rclone.ps1'
@'
$global:MediaTestRcloneCalls += 1
$global:MediaTestRcloneArguments = $args
$global:LASTEXITCODE = $global:MediaTestRcloneExit
'@ | Set-Content -LiteralPath $mockRclone
function global:conda { $global:LASTEXITCODE = $global:MediaTestCondaExit }
try {
    $global:MediaTestCondaExit = 1
    $global:MediaTestRcloneCalls = 0
    $global:MediaTestRcloneExit = 0
    $caught = $false
    try { & (Join-Path $fixture 'scripts/sync-media.ps1') -RclonePath $mockRclone } catch { $caught = $_.Exception.Message -match 'optimization failed' }
    if (-not $caught -or $global:MediaTestRcloneCalls -ne 0) { throw 'Optimization failure did not prevent upload' }

    $global:MediaTestCondaExit = 0
    & (Join-Path $fixture 'scripts/sync-media.ps1') -RclonePath $mockRclone
    $arguments = $global:MediaTestRcloneArguments
    if ($arguments[0] -ne 'copy' -or $arguments[1] -ne (Join-Path $fixture 'images') -or $arguments[2] -ne 'r2-talks:talks') { throw 'Wrong upload operation, source, or destination' }
    if ($arguments -contains 'sync' -or $arguments -contains '--delete-excluded') { throw 'Destructive upload operation' }
    foreach ($filter in @('- Thumbs.db', '- .DS_Store', '- ._*', '- __MACOSX/**', '+ *.png', '- **')) {
        if ($arguments -notcontains $filter) { throw "Missing filter: $filter" }
    }

    $global:MediaTestRcloneExit = 1
    $caught = $false
    try { & (Join-Path $fixture 'scripts/sync-media.ps1') -RclonePath $mockRclone } catch { $caught = $_.Exception.Message -match 'upload failed' }
    if (-not $caught) { throw 'Upload failure was not reported' }
    Write-Host 'PASS: optimization abort, copy destination and filters, upload error propagation.'
} finally {
    Remove-Item Function:\conda
    # Only delete the generated test directory, after validating its absolute path.
    $resolved = [IO.Path]::GetFullPath($fixture)
    $prefix = [IO.Path]::GetFullPath($cache) + [IO.Path]::DirectorySeparatorChar
    if (-not $resolved.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe test cleanup path' }
    Remove-Item -LiteralPath $resolved -Recurse -Force
}
