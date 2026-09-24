[CmdletBinding()]
param(
    [string]$CondaEnvironment = "urban-modelling",
    [string]$RclonePath = "",
    [string]$Remote = "r2-talks:talks",
    [string]$PublicBaseUrl = "https://talks-assets.wccarleton.org",
    [string]$VerifyImage = ""
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$imageDir = Join-Path $repoRoot "images"
$archiveDir = Join-Path $repoRoot "media-originals"
if (-not $RclonePath) { $RclonePath = Join-Path $repoRoot "tools/rclone/rclone.exe" }
if (-not (Test-Path -LiteralPath $RclonePath -PathType Leaf)) {
    throw "rclone is missing: $RclonePath. See authoring/media-upload.md."
}
if (-not (Test-Path -LiteralPath $imageDir -PathType Container)) {
    throw "Create images/ and add the images to upload first."
}

& conda run --no-capture-output -n $CondaEnvironment python `
    (Join-Path $PSScriptRoot "optimize-media.py") --images $imageDir --archive $archiveDir
if ($LASTEXITCODE -ne 0) { throw "Media optimization failed; upload cancelled." }

# Only supported image files are uploaded. Original archives and credentials
# live outside this folder; copy never deletes destination objects.
& $RclonePath copy $imageDir $Remote --progress --ignore-case `
    --filter "- Thumbs.db" --filter "- desktop.ini" --filter "- .DS_Store" `
    --filter "- ._*" --filter "- __MACOSX/**" `
    --filter "+ *.jpg" --filter "+ *.jpeg" --filter "+ *.png" --filter "+ *.webp" `
    --filter "- **"
if ($LASTEXITCODE -ne 0) { throw "R2 upload failed." }
Write-Host "Public image base: $PublicBaseUrl"

if ($VerifyImage) {
    $imageRoot = [IO.Path]::GetFullPath($imageDir) + [IO.Path]::DirectorySeparatorChar
    $localImage = [IO.Path]::GetFullPath((Join-Path $imageDir $VerifyImage))
    if (-not $localImage.StartsWith($imageRoot, [StringComparison]::OrdinalIgnoreCase)) {
        throw "VerifyImage must be relative to images/."
    }
    if (-not (Test-Path -LiteralPath $localImage -PathType Leaf)) {
        throw "Verification image does not exist: $localImage (check PNG rename reports)."
    }
    $key = $localImage.Substring($imageRoot.Length).Replace('\', '/')
    $encodedKey = (($key.Split('/') | ForEach-Object { [Uri]::EscapeDataString($_) }) -join '/')
    $url = $PublicBaseUrl.TrimEnd('/') + '/' + $encodedKey
    $download = [IO.Path]::GetTempFileName()
    try {
        Invoke-WebRequest -Uri $url -UseBasicParsing -OutFile $download
        if ((Get-FileHash -LiteralPath $download -Algorithm SHA256).Hash -ne
            (Get-FileHash -LiteralPath $localImage -Algorithm SHA256).Hash) {
            throw "Public image differs from the local upload: $url (possibly a cached older version)."
        }
        Write-Host "Verified public image (SHA-256 matches): $url"
    } finally {
        Remove-Item -LiteralPath $download -ErrorAction SilentlyContinue
    }
}
