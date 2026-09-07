# Cute Zine Maker

A very cute, rainbow-pastel, **local-first mini-zine editor** for iOS, Android, and web (Flutter). Doodle with a glitter pen, stamp ransom-note letters and rhinestones, drop text, and swap scrapbook page papers. Nothing leaves the device.

No accounts. No cloud. No API keys.

The Dart package is still named `petal_press` — only the **display name** is Cute Zine Maker.

## Run it

You need the current stable Flutter SDK (`flutter --version`).

```bash
flutter pub get
flutter run
```

Pick a phone or simulator when prompted. Web also works for a quick look:

```bash
flutter run -d chrome
# or a headless preview:
flutter run -d web-server --web-hostname=0.0.0.0 --web-port=45231
```

`flutter analyze` and `flutter test` should stay clean.

## Page size

A classic 8-page mini-zine is **one US Letter sheet (8.5 × 11 in) folded into eighths**. Each portrait panel is:

| | |
|---|---|
| Width | **2.75 in** |
| Height | **4.25 in** |
| Logical canvas | **825 × 1275** px at **300 DPI** |

These live in `lib/models/page_size.dart` (`ZinePageSize`). The on-screen page stays this aspect ratio, letterboxed. Ink is stored as point data so you can reopen and keep drawing.

## Editor chrome

- **Phone / narrow web** (shortest side &lt; 600 **and** width &lt; 840): tools stay in a **bottom tray**.
- **Wide web / large windows** (shortest side ≥ 600 **or** width ≥ 840): tools live in a **collapsible left side menu** (chevron to collapse to a thin rail). Open/closed is remembered on device.
- The zine page itself is still *your* paper color and pattern — only the chrome around it is rainbow pastel.

Resize a browser window to watch the layout swap.

## PDF export

Tap the share/export button and choose:

1. **One page per PDF page** — each page is 2.75 × 4.25 in (same as the editor).
2. **8-page folded Letter** — landscape 11 × 8.5 in sheets so you can print, fold, slit, and nest a booklet.

Fold imposition (one signature = 8 zine pages):

```
Landscape Letter
┌────────┬────────┬────────┬────────┐
│  7 °   │  6 °   │  5 °   │  4 °   │  top, each page rotated 180°
├────────┼────────┼────────┼────────┤
│   8    │   1    │   2    │   3    │  bottom, right-side-up
└────────┴────────┴────────┴────────┘
```

After fold/cut, page 1 is the cover and the book reads 1–8. The top row is **7 · 6 · 5 · 4** (not 4–7) so those panels read correctly after the 180° rotation. Cells are exact 2.75 × 4.25 in tiles (no rescale). Zines that are not a multiple of 8 are **blank-padded to groups of 8** (one Letter sheet per 8 pages). The dialog mentions this.

Print single-sided, landscape, actual size (no “fit to page”). Then fold into quarters, slit the center along the long fold, and nest into a book.

## What’s in this slice

- Create / rename / delete / open zines on device
- 8 blank pages by default (other counts allowed)
- Add / reorder / delete pages
- Pen: pastel palette, color picker, thickness, opacity, **sparkle**
- Page backgrounds: solid pastels + hearts, palaka, waves, dots, stars, gingham
- Sticker tin: A–Z, 0–9, glitter shapes, gems, glue outlines, buttons, sequins, sticky notes, faces
- Text boxes (bundled Fredoka)
- Layers: paper → ink → stickers/text
- Undo / redo, local JSON save + thumbnail
- PDF: 1-up **or** folded Letter

## Deferred

- Flood-fill / bucket
- Email-link auth, cloud upload, public / passcode sharing
- Geo / zip discovery

## Architecture

- One `CustomPaint` + scene graph. No Flame. No widget-per-stroke.
- Sparkle is baked along the path so PDF rasters match the editor.
- Persistence is local `SharedPreferences` (JSON + PNG thumbs). Guest-only.

## License

Personal project. Fredoka and Nunito fonts are OFL.
