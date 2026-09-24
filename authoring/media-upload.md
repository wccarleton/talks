# Prepare and upload talk images

This adapts `purakohker/scripts/optimize-media.py` and `sync-media.ps1` for talks.
There are no website branding exclusions or gallery-generation steps.

## Storage and public URLs

| Purpose | Location |
|---|---|
| Local upload copies | `images/` (ignored by Git) |
| Preserved originals | `media-originals/` (ignored, outside the upload tree) |
| Local rclone executable | `tools/rclone/rclone.exe` (ignored) |
| Destination | `r2-talks:talks` |
| Public host | `https://talks-assets.wccarleton.org` |

`images/koh-ker/map.webp` uploads with object key `koh-ker/map.webp`. Its URL is
`https://talks-assets.wccarleton.org/koh-ker/map.webp`. Neither the `images/`
directory nor the bucket name is prepended to the object key.

The tracked scripts, slide sources, and configuration contain no credentials.
Local tools, generated copies, originals, `.env` files, and rclone configuration
files are ignored. Keep any credential files outside `images/` and preferably
outside the repository entirely. The upload script only includes JPEG, PNG,
and WebP files and excludes common Windows/macOS junk.
`scripts/r2access.env` is explicitly ignored and is not imported by the script;
authentication uses rclone's external configuration (or rclone's standard
environment variables).

## One-time setup

1. Install Pillow in the existing Conda environment:

   ```powershell
   conda install -n urban-modelling -c conda-forge pillow
   ```

   New environments can use `conda env create -f environment.yml`.

2. Place the Windows rclone executable at `tools/rclone/rclone.exe`. The initial
   setup here reuses the local executable from `purakohker` (v1.75.1); a fresh
   checkout needs its own copy. Alternatively pass `-RclonePath` to the script.

3. In Cloudflare R2, create credentials with **Object Read & Write** access to
   the **talks** bucket. Configure a separate remote to preserve the website's
   existing `r2` configuration:

   ```powershell
   ./tools/rclone/rclone.exe config
   ```

   Create remote `r2-talks`; choose Amazon S3-compatible storage, provider
   Cloudflare, and enter the access key ID and secret in the local interactive
   prompt. Use the account's S3 endpoint shown in Cloudflare **without** the
   trailing `/talks`. The bucket belongs in `r2-talks:talks`, not in the endpoint.
   Use region `auto` if prompted; leave unrelated options at their defaults.
   Do not put keys in these scripts, slide metadata, or Git.

   Find the external credentials file with:

   ```powershell
   ./tools/rclone/rclone.exe config file
   ./tools/rclone/rclone.exe lsf r2-talks:talks --max-depth 1
   ```

   An empty listing with exit code zero is valid for a new bucket. The original
   `r2` remote returned Access Denied for this bucket during setup; it should
   continue serving the original website rather than being overwritten.

4. Create `images/` and place images in subdirectories matching your intended
   object keys. Keep originals elsewhere if you also maintain a master archive.
   `media-originals/` is an additional local preservation copy, not a remote backup.

## One-command workflow

From the repository root, run:

```powershell
./scripts/sync-media.ps1
```

This optimizes first, stops on failure, then executes **rclone copy** from
`images/` to `r2-talks:talks`. Changed objects may be replaced, but remote objects
are never deleted. Unrelated old files, including PNG keys replaced by WebP
references, remain on R2. Originals are never uploaded by this command.

To also verify a particular uploaded image through the public host:

```powershell
./scripts/sync-media.ps1 -VerifyImage 'koh-ker/map.webp'
```

Verification downloads the public URL and compares its SHA-256 to the local
optimized file. Supply the final filename if PNG conversion will rename it.
A stale cached response or inaccessible public host causes verification to fail;
the upload may already have succeeded. The S3 API endpoint is used only by
rclone, never as a public image URL.

Optional parameters are `-CondaEnvironment`, `-RclonePath`, `-Remote`, and
`-PublicBaseUrl`. Keep the remote destination and public base consistent if you
change them. The defaults are in `scripts/sync-media.ps1`.

## Optimization and recovery

- Recursively inspect `.jpg`, `.jpeg`, `.png`, and `.webp` (case-insensitive).
- Leave bytes untouched when **both dimensions are at most 2000 px** and the
  file is **at most 1,000,000 bytes**.
- Otherwise apply EXIF orientation, proportionally resize with Lanczos to a
  maximum edge of 2000 px, and never upscale.
- JPEG retains its filename and is encoded at quality 88, optimized and
  progressive. WebP retains its filename and uses quality 85, method 6.
  PNGs requiring processing become WebP, preserving transparency.
- The byte threshold triggers processing; it is **not an output-size cap**.
  An output may remain larger than 1 MB. A later run may recompress it again.
- Before replacing a source, archive its exact bytes as, for example,
  `media-originals/koh-ker/map.012345abcdef.png`, with a 12-character SHA-256
  suffix and the original directory structure. Verify the full archive hash.
- Verify the encoded image by decoding it and checking its format and dimensions.
  Replacements use atomic publication on the same filesystem. PNG conversion
  refuses any existing WebP target, including a name differing only in case.
  No existing WebP is overwritten by a conversion.
- Each PNG rename is printed immediately as `RENAMED: old.png -> new.webp` so
  slide references can be updated even if a later file fails.

Optimization is per-file, not a transaction over the whole directory: earlier
successful files remain optimized if a later image fails, but uploading is
cancelled. Archives allow recovery. Do not edit source images while the command
runs or run concurrent optimization jobs. Symlinks and oversized animated images
are rejected rather than risking an external file or silently losing animation.
Atomic no-overwrite publication uses hard links; use a local filesystem supporting
hard links, such as NTFS, for the upload and archive folders.

To optimize without uploading:

```powershell
conda run -n urban-modelling python scripts/optimize-media.py --images images --archive media-originals
```

## Use the existing resolver

The repository's `assets-base` is now `https://talks-assets.wccarleton.org`:

```markdown
![Trench profile](assets:koh-ker/profile.webp)
```

For local editing, keep the source unchanged and set the base to `images`:

```powershell
$env:TALKS_ASSETS_BASE = 'images'
quarto preview
Remove-Item Env:TALKS_ASSETS_BASE
```

Per-deck overrides, direct HTTPS URLs, full local paths, and the existing offline
export image downloading continue to work. The resolver itself is unchanged.
See [image resolution](images.md). Uploading media is a separate local command;
the GitHub Pages workflow does not have R2 credentials or upload media.

## Checks

```powershell
conda run -n urban-modelling python scripts/test_optimize_media.py
powershell -NoProfile -File scripts/test_sync_media.ps1
```

The tests use disposable images and mocked uploads; they do not modify R2.

The live setup check uploaded
`https://talks-assets.wccarleton.org/_pipeline-check/upload-check.webp` and
verified its SHA-256 against the local file. The test PNG was resized from
2400 × 1200 to 2000 × 1000, converted to WebP, and its original archived under
`media-originals/_pipeline-check/`. The small test object is left available as
a connectivity check.
