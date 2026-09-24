## House Style Slide Elements

The working lecture style uses plain Quarto/reveal markup first, with a few small utility classes from `mpg.scss`.

### Core content slide pattern

Use this for most text-heavy analytical slides: two columns for the main contrast or paired ideas, then a full-width implication or fragment beneath the columns.

```markdown
## Slide Title

:::: {.columns} <!-- can inclue .col-center-container to center content within columns -->
::: {.column width="50%"} <!-- if centering, then .v-center and/or .h-center -->
**column title**:

- bullet one
- buller two
  
:::
::: {.column width="50%"} <!-- if centering, then .v-center and/or .h-center -->
![](../assets/content/path/to/figure)
:::
::::


::: {.fragment} 
Key slide point to emphasize. Can appear in a column instead if one column is so long that this fragment would be pushed below the viewably slide area.
:::

---
```

### House style classes

- `::: {.callout-card}` creates a light grey card with a teal left accent. Use it for key concepts, questions, or the more important column.
- `::: {.fragment}` is for delayed takeaway text. In this theme fragments are italic, dark grey, and spaced away from surrounding content.
- `<span class="inline-list">...</span>` creates compact inline list items. Use the bullet character inside the text when useful: `item •`.
- Native Quarto columns should be preferred over custom grid CSS:
  ```markdown
  :::: {.columns}
  ::: {.column width="50%"}
  Left column
  :::

  ::: {.column width="50%"}
  Right column
  :::
  ::::
  ```

Avoid `###` headings inside columns when they are meant only as visual labels. In reveal slides, heading levels can be interpreted as slide structure. Prefer bold labels such as `**Key concept**` inside columns and callouts.

### Framed images

Apply `.img-card` to an image for a simple white photo frame with a slightly
wider bottom edge, a fine border, and a subtle shadow:

```markdown
![Fieldwork at Koh Ker](assets:koh-ker/fieldwork.jpg){.img-card height=350 fig-align="center"}
```

The frame includes 8px padding on the top and sides and 22px at the bottom.
Text in the square brackets appears beneath the image inside the same frame,
as a small centered caption. For captioned figures, explicit image dimensions
size the image itself; the frame and caption add to the total card height.
`object-fit: contain` keeps the whole image visible. Omit `.img-card` when a
plot should have no frame.

In Reveal decks, `filters/image-cards.lua` automatically disables Quarto's
image stretching for `.img-card`, keeping captions inside the figure on both
top-level slides and inside columns. No manual `.nostretch` is needed.
Set an image height when needed to leave room for the caption and slide text:

```markdown
![Caption](assets:koh-ker/fieldwork.jpg){.img-card height=600 fig-align="center"}
```

### Image diagrams

Use `.image-diagram` when a slide needs a compact, predictable arrangement of two, three, or four images. This is useful for visual comparisons, process diagrams made from separate panels, or recurring examples where you want the same layout to work both on a full slide and inside a column.

Two images are arranged side by side:

```markdown
::: {.image-diagram .image-diagram-2}
![](../assets/content/example/a.png)

![](../assets/content/example/b.png)
:::
```

Three images place one image centered on the top row and two images below it:

```markdown
::: {.image-diagram .image-diagram-3}
![](../assets/content/example/top.png)

![](../assets/content/example/bottom-left.png)

![](../assets/content/example/bottom-right.png)
:::
```

Add `.image-panel` inside the same diagram when you want titles, numbers, or citation keys attached to each image:

```markdown
<div class="image-diagram image-diagram-3 image-diagram-small">
<div class="image-panel">
<div class="image-label">1. Angkor Thom</div>
<img src="../assets/content/example/top.png">
</div>
<div class="image-panel">
<div class="image-label">2. Kerkenes Dag</div>
<img src="../assets/content/example/bottom-left.png">
</div>
<div class="image-panel">
<div class="image-label">3. Falerii Novi</div>
<img src="../assets/content/example/bottom-right.png">
</div>
</div>

::: {.small}
1. Angkor Thom: Ichita et al. 2016, DOI: 10.4236/ad.2016.41003.
:::
```

Four images use a 2 by 2 grid:

```markdown
::: {.image-diagram .image-diagram-4}
![](../assets/content/example/a.png)

![](../assets/content/example/b.png)

![](../assets/content/example/c.png)

![](../assets/content/example/d.png)
:::
```

The helper can be nested inside a Quarto column:

```markdown
:::: {.columns .col-center-container}
::: {.column width="50%" .v-center}
**Evidence types**
:::

::: {.column width="50%"}
::: {.image-diagram .image-diagram-3 .image-diagram-small}
![](../assets/content/example/top.png)

![](../assets/content/example/bottom-left.png)

![](../assets/content/example/bottom-right.png)
:::
:::
::::
```

Optional modifiers:

- `.image-diagram-small` lowers the image height for use inside columns or dense slides.
- `.image-diagram-tall` allows larger images when the diagram is the main slide content.
- `.image-diagram-tight` reduces spacing between images.

### Font Awesome icons

Slides use Font Awesome-style class names. The site currently loads Font Awesome from a CDN, so these icons render when you have an internet connection. Use the normal HTML syntax inside `.qmd` slides:

```html
<i class="fa-solid fa-magnifying-glass"></i>
```

Icons inherit the theme accent colour from `mpg.scss`, so they match the teal heading colour by default. Add `theme-icon` when you want a slightly larger icon:

```html
<i class="fa-solid fa-triangle-exclamation theme-icon"></i>
```

Example in slide text:

```markdown
<p>
  <i class="fa-solid fa-magnifying-glass theme-icon"></i>
  <strong>Similar temples tend to be founded at similar times.</strong>
</p>
```

Useful icon names:

- `fa-magnifying-glass` for inspection or assumptions
- `fa-triangle-exclamation` for warnings
- `fa-circle-info` for notes
- `fa-chart-line` for trends
- `fa-clock` for chronology
- `fa-map-location-dot` for spatial examples
- `fa-brain` for thinking points
- `fa-arrow-right-long` for implications (swap directions and with/without '-long')
- `fa-quote-left` for qutation emphasis
- `fa-question` for question mark

---


