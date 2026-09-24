# Presentation fonts

The Reveal theme uses Open Sans for body text and Roboto Slab at weight 600 for
headings. `fonts.css` loads bundled variable TrueType fonts, including real Open
Sans italics. Body text uses slate grey (`#374151`); heading accents remain teal.

Original files are distributed through the Google Fonts repository:

- [Open Sans](https://github.com/google/fonts/tree/main/ofl/opensans):
  `OpenSans[wdth,wght].ttf` and `OpenSans-Italic[wdth,wght].ttf`, renamed locally
  for simple URLs. See `OpenSans-OFL.txt` for the SIL Open Font License.
- [Roboto Slab](https://github.com/google/fonts/tree/main/apache/robotoslab):
  `RobotoSlab[wght].ttf`, renamed locally. See `RobotoSlab-LICENSE.txt` for the
  Apache License 2.0.

These small shared styling assets belong in Git, rather than the R2 media upload
pipeline. The website build copies this folder, and the slide defaults load the
stylesheet. Viewers do not need to install fonts for browser presentations.
Self-contained HTML exports can embed the font resources. PowerPoint uses its
own theme and font-installation/embedding workflow; CSS fonts do not configure it.
