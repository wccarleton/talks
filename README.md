# Academic talks

One Quarto source file per talk, with shared Reveal styling and bibliography.

## Layout

- `slides/`: published talks; `_metadata.yml` supplies all shared slide defaults.
- `templates/talk-template.qmd`: starter to copy into `slides/`.
- `examples/`: basic and timeline style demonstrations, excluded from the site build.
- `index.qmd`: automatic talk listing, newest first.
- `references.bib`: shared bibliography; `bibliography.qmd` lists the full library.
- `mpg.scss`, `title-slide.html`, `assets/branding/`: shared presentation styling.
- `authoring/slide-elements.md`: examples of the available slide components.
- `docs/`: generated website output, ignored by Git.
- `_legacy/docs/`: preserved output from the copied lecture site, ignored by Git.

## Create a talk

In PowerShell, from the project directory:

```powershell
Copy-Item templates/talk-template.qmd slides/my-talk.qmd
quarto preview slides/my-talk.qmd
```

Set the title, subtitle, date (`YYYY-MM-DD`), description, event, and location.
The template uses a lightweight SVG image placeholder: replace these images and
update their alternative text and credits. Replace the example citation as needed.
Talks inherit the shared author and Reveal settings from `slides/_metadata.yml`;
individual talks can override these settings in their front matter.

Use paths relative to the talk, such as `../assets/branding/section_bg.png`.
The title partial assumes talks live directly inside `slides/`.

Every `.qmd` directly in `slides/` is rendered and included in the homepage listing.
Keep unfinished drafts outside that directory until ready to publish.

## Preview and build

```powershell
quarto preview
quarto render
```

The website build includes the homepage, bibliography, and talks. With no talks
added yet, the homepage listing is empty. Templates and examples are excluded.

Preview a style example explicitly:

```powershell
quarto preview examples/basic.qmd
quarto preview examples/timeline.qmd
```

Examples reuse `slides/_metadata.yml`. Explicit example renders produce local
HTML and support folders beside the example source; these are ignored by Git.

## Offline and PowerPoint export

### PowerPoint preserving the Reveal appearance (recommended)

`scripts/export-slides.py` renders the deck as Reveal HTML, captures each slide
as a PNG, and embeds one image per PowerPoint slide. The default is 3840 x 2160
pixels for the shared 1920 x 1080 theme. Speaker notes are copied into PowerPoint.
Text and figures are baked into each image; animations and interactive content
are static. Fragments are all shown on a single slide. Browser navigation controls
are hidden, while slide numbers, branding, and the deck's layout are retained.

One-time setup from the repository root in PowerShell (Python 3.10+ and Quarto
must be installed):

```powershell
python -m venv tools/export-venv
.\tools\export-venv\Scripts\python.exe -m pip install -r scripts/requirements-export.txt
```

First export, including the browser download:

```powershell
.\tools\export-venv\Scripts\python.exe scripts/export-slides.py slides/2026_icc11_kohker_update.qmd --install-browser
```

Subsequent exports:

```powershell
.\tools\export-venv\Scripts\python.exe scripts/export-slides.py slides/2026_icc11_kohker_update.qmd
```

The resulting file is
`export/2026_icc11_kohker_update/image-pptx/2026_icc11_kohker_update-images.pptx`.
Individual PNGs are in its `images/` directory; `manifest.json` lists the current
export's slides. Re-exporting overwrites matching output files. If a deck gets
shorter, older extra PNGs may remain, but are not included in the new PowerPoint.
Use `--scale 1` for 1920 x 1080 images, or `--scale 3` for 5760 x 3240 images.
Higher resolution increases file size; it cannot add detail to low-resolution
source photographs. Source image URLs must be reachable during rendering.

On macOS/Linux, use `tools/export-venv/bin/python` in place of the Windows Python
path above. Chromium is downloaded to the ignored `tools/playwright/` directory
unless `PLAYWRIGHT_BROWSERS_PATH` is set. No PowerPoint installation is required.

### Editable PowerPoint and offline HTML (original exporter)

Generated offline decks and PowerPoint files go under `export/`, which is
ignored by Git. The tracked export wiring is `_quarto-export.yml`,
`scripts/export-talk.sh`, and `filters/assets.lua`.

From Bash or WSL, export the current talk with:

```bash
scripts/export-talk.sh slides/latent_human_influence.qmd
```

This renders:

- `export/latent_human_influence/offline/slides/latent_human_influence.html`: a self-contained Reveal HTML export.
- `export/latent_human_influence/pptx/slides/latent_human_influence.pptx`: a PowerPoint export.

The export profile sets `export-remote-images: true`, so direct HTTPS Markdown
images are downloaded during rendering and embedded for offline/PPTX output.
Normal website renders keep HTTPS image links as remote URLs. Remote images must
be reachable when you run the export command.

## Typography

The slide theme bundles Open Sans for body text and Roboto Slab for headings,
with slate-grey body text and teal accents. No font installation is needed for
browser presentations. Font files and licenses live in `assets/fonts/`; these
are shared styling assets tracked with the theme. PowerPoint styling is separate.

## Images

Use `![Caption](assets:talk-name/image.png)` with a configurable URL or local
folder base, a full local file path, or a direct HTTPS image URL. See
[image storage and configuration](authoring/images.md) for syntax and local/R2
setup. Media stays outside Git; local images are packaged in generated output.

Put upload images in the Git-ignored `images/` folder and run
`./scripts/sync-media.ps1` to optimize and upload them to `r2-talks:talks`.
Originals are preserved in Git-ignored `media-originals/`. Public image links use
`https://talks-assets.wccarleton.org` plus the image's relative path.
See [media upload setup and workflow](authoring/media-upload.md).

## Current scope

The website, shared Reveal styling, and pluggable image resolution are configured.
The local media preparation/upload scripts are configured; R2 access uses a
separate locally configured `r2-talks` remote. Font Awesome currently
loads from a CDN.
Do not commit generated output; the old workflow of committing `docs/` is retired.
Branding and lightweight placeholder assets are copied as shared project resources.

## Website deployment

Pushing to `main` runs `.github/workflows/publish.yml`: GitHub Actions installs
Quarto 1.9.37, renders the site, and deploys `docs/` as a GitHub Pages artifact.
Generated output is never committed. The workflow can also be run manually from
the repository's Actions tab.

In GitHub Settings → Pages, select **GitHub Actions** as the source and set the
custom domain to `talks.wccarleton.org`. Enable HTTPS when GitHub offers it.
Cloudflare DNS should have a `talks` CNAME targeting `wccarleton.github.io`.

The build runner cannot access laptop or external-drive paths. Published talks
must use publicly reachable image URLs (directly or through `assets-base`), or
files available to the build. Upload images before publishing slides that reference them.

The copied research notebooks, their figures, and `rubric-print.css` remain for
review; they are not part of the configured site build.

See [slide components](authoring/slide-elements.md) for authoring conventions and
[LICENSE](LICENSE) for the project license.
