# Images without storing the media in Git

Use ordinary Markdown images. Three source forms can be mixed in one talk:

```markdown
![Excavation map](assets:koh-ker/map.png){width=80%}
![Field photograph](<E:/Talk media/koh-ker/photo.jpg>){width=80%}
![Published figure](https://example.org/figures/figure-1.png){width=80%}
```

`assets:` is a prefix implemented by `filters/assets.lua`, not built-in Quarto
syntax. It joins the image's path to an `assets-base` setting. Use forward
slashes and wrap paths containing spaces in angle brackets.

## Choose the asset location

For a shared hosted location, add this top-level setting to `_quarto.yml`:

```yaml
assets-base: https://media.example.org/talks
```

The setting is already present in this repository with an empty value; edit it
when you choose storage. Decks without `assets:` images need no configured base.
For a per-deck override, put the same key in that QMD's YAML front matter:

```yaml
---
title: "Mapping Human Influence"
assets-base: 'E:/Talk media/koh-ker'
---
```

Then `![Map](assets:map.png)` uses that deck's folder. Omit the key to inherit
the repository default. Individual images can always use full paths or URLs
regardless of the base setting.

The first image above then uses
`https://media.example.org/talks/koh-ker/map.png`. Use a public HTTPS delivery URL
for R2 or another host, not an S3 API endpoint or bucket credentials. A direct
image URL is needed; a webpage containing an image is not an image source.

For a laptop or external drive, create the Git-ignored `_quarto-local.yml`:

```yaml
assets-base: 'E:/Talk media'
```

Activate it explicitly:

```powershell
quarto preview --profile local
quarto render --profile local
```

Alternatively override the base for a terminal session:

```powershell
$env:TALKS_ASSETS_BASE = 'E:/Talk media'
quarto render
Remove-Item Env:TALKS_ASSETS_BASE
```

The environment variable takes precedence over metadata. A talk can specify
`assets-base` in its front matter to override the project's metadata. Local
relative bases, such as `assets/content`, resolve from the repository root.
Use absolute paths for laptop folders outside the repository.

Keep the same directory layout in local storage and on the remote host to switch
between them without editing image statements. No bucket provisioning, upload,
download synchronization, or authentication is performed by the filter.

## What gets built and committed

- HTTPS sources stay as remote references in normal HTML output.
- Local absolute paths and local `assets:` images are read during rendering and
  packaged into output resources. Generated filenames use content hashes so
  images with the same filename from different folders do not collide.
- Ordinary relative image paths continue to work as before.
- Missing local files and an unconfigured `assets:` prefix stop the build with
  an actionable error rather than silently producing broken slides.

Commit the QMD files, filter, shared configuration, and branding. Generated
`docs/`, optional `assets/content/`, `.media-cache/`, and `_quarto-local.yml` are
ignored. The filter does not write original media into the tracked source tree.
Build output can contain images: keep it out of Git and deploy it separately.
Changing `.gitignore` does not untrack files already committed to an existing repo.

Hosted decks cannot access your laptop or external drive. A build using local
files must deploy the generated media alongside the HTML. A build using remote
URLs needs those images to be reachable by viewers. Local HTML with remote URLs
still needs internet; `embed-resources: true` requests a self-contained export.
PowerPoint and PDF have their own format limitations; this filter resolves image
sources but does not implement the complete export workflow.

The resolver handles Markdown images, including images within columns and
figures. It does not rewrite raw HTML `<img>` tags, CSS URLs, video sources, or
Reveal background attributes. Keep shared slide backgrounds under
`assets/branding/` with normal relative paths.

Try the small built-in example with no external storage configured:

```powershell
quarto render examples/media.qmd
```
