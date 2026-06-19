# Typography for Local Web Tools

When a local web tool needs both Chinese and English text, font pairing matters. This covers the common CDN sources and CSS patterns.

## English titles → Google Fonts

Use Google Fonts for English display/title faces. Inter is a strong default — clean, modern, good weight range:

```html
<link href="https://fonts.googleapis.com/css2?family=Inter:opsz,wght@14..32,300;14..32,400;14..32,500;14..32,600&display=swap" rel="stylesheet">
```

Declare as a CSS variable for easy reuse:

```css
:root {
  --font-display: "Inter", -apple-system, "PingFang SC", "Microsoft YaHei", sans-serif;
}
```

Apply to: sidebar tabs, section labels (`.label`), date numbers, view headers, song names, notes labels — anything that's a short English heading or label.

## Chinese body text → MiSans (jsDelivr CDN)

MiSans is Xiaomi's open-source Chinese font. Clean, modern, excellent legibility at small sizes. Available via jsDelivr:

```html
<!-- MiSans Normal (400) -->
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/misans@4.0.0/lib/Normal/MiSans-Normal.min.css">
<!-- MiSans Medium (500) -->
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/misans@4.0.0/lib/Normal/MiSans-Medium.min.css">
<!-- MiSans Semibold (600) -->
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/misans@4.0.0/lib/Normal/MiSans-Semibold.min.css">
```

Set on body, everything inherits:

```css
body {
  font-family: "MiSans", -apple-system, "PingFang SC", "Microsoft YaHei", sans-serif;
}
```

**Fallback chain:** MiSans → system PingFang SC (macOS/iOS) → Microsoft YaHei (Windows) → sans-serif. If the MiSans CDN fails, the tool still looks fine.

## Dark-theme text readability on frosted glass

When text sits on frosted glass panels (`backdrop-filter: blur()`), default color variables often feel washed out. Key adjustments:

| Variable | Role | Default feel | Boost target |
|----------|------|-------------|--------------|
| `--ink-dim` | Secondary text, inactive tabs, placeholder hints | ~55% opacity feel | ~80% — `#C8C4E8` on `#07070F` |
| `--ink-faint` | Timestamps, subtle labels | ~40% opacity feel | ~60% — `#9B96C0` |
| `font-weight` | Body text | Often 300 (inherited from Pico.css or reset) | 400 minimum |
| Section labels | `.label`, `.edit-dim-label` | 400 | 500 — adds structure |

Don't use pure white (`#FFFFFF`) for body text on dark frosted glass — it creates too much contrast and feels harsh. Stay in the `#E8E6F5` range.

## Removing an existing font

When replacing fonts, check three places:
1. **HTML `<head>`** — remove old `<link>`, add new font links
2. **CSS `:root`** — update `--font-display` variable if present
3. **CSS selectors** — any element with explicit `font-family` (often `.date .num`, `.sidebar-tab`, etc.)

Always verify with a page load that no 404s appear for the old font URL.
