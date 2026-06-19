# Glass Morphism — Two-Tier Blur System

When building dark-theme web tools with a **visual background** (video, image, gradient) behind the UI, use a two-tier backdrop-filter blur system to separate structure from input.

## The Two Tiers

| Tier | Blur | Saturate | Background | Applies to |
|---|---|---|---|---|
| **Clear glass** | `8px` | `140%` | `rgba(10,12,22,.45)` | panels, sidebar, cards |
| **Frosted glass** | `16–20px` | `130%` | `rgba(8,10,18,.60)` | text inputs, textareas |

**Clear glass** — structural elements. Sharp enough to see the background through, solid enough to read UI chrome. Feels light, clean, modern.

**Frosted glass** — input areas. Heavy blur quiets the background so long text is comfortable to read. The deeper background provides a calm, focused writing surface.

## CSS Variable Pattern

```css
:root {
  /* Clear glass */
  --pane:      rgba(10,12,22,.45);   /* panel bg */
  --pane-hi:   rgba(255,255,255,.25); /* ::before highlight */
  --clear-hover: rgba(255,255,255,.08);

  /* Frosted glass */
  --write:     rgba(8,10,18,.60);     /* input bg */

  /* Borders — sharper for aurora/video backgrounds */
  --line:       rgba(255,255,255,.30);
  --line-soft:  rgba(255,255,255,.18);
  --line-strong:rgba(255,255,255,.35);
}
```

## Why Two Tiers

A single blur value is a compromise:
- **Too low (4–6px):** text areas feel jittery, eyes fight to separate text from background
- **Too high (20px+ on panels):** everything looks heavy, loses the "floating above" illusion

Two tiers give each element class the right blur for its job.

## Card-Level Elements

`.frag-item`, `.song-item`, `.spark-lib-item` use the **clear glass** tier (8px) — they're structural containers, not writing surfaces.

For inline textareas inside cards (`.note-textarea`), use the **frosted** tier.

## Order of Operations

When converting an existing frosted-glass project to this two-tier system:
1. Update `:root` variables first
2. Lower `.panel` blur to 8px
3. Lower `.sidebar` blur to 8px
4. Lower card blurs to 8px
5. Raise `.field` / `.area` blur to 18px
6. Add blur to any missing inline textareas
7. Verify all input areas have backdrop-filter
