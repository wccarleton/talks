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

## Images

Use `![Caption](assets:talk-name/image.png)` with a configurable URL or local
folder base, a full local file path, or a direct HTTPS image URL. See
[image storage and configuration](authoring/images.md) for syntax and local/R2
setup. Media stays outside Git; local images are packaged in generated output.

## Current scope

The website, shared Reveal styling, and pluggable image resolution are configured.
Bucket provisioning/synchronization, offline export presets, and PDF/PowerPoint
workflows are not configured yet. Font Awesome currently
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
files available to the build. Image storage is still to be configured.

The copied research notebooks, their figures, and `rubric-print.css` remain for
review; they are not part of the configured site build.

See [slide components](authoring/slide-elements.md) for authoring conventions and
[LICENSE](LICENSE) for the project license.
