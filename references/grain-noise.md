# Grain / Noise Texture Overlay (SVG feTurbulence)

Procedural grain texture via inline SVG — no external image files, pure CSS+SVG.

## When to use

- Background has large gradient blobs (`filter: blur()` circles) that show colour banding
- You want a subtle film-grain / mist texture without importing PNGs
- Dark dreamy themes where a light noise layer adds depth

## How it works

An inline `<svg>` element with `feTurbulence` (fractalNoise) + `feColorMatrix` (desaturate to grayscale) renders procedural noise. Positioned `fixed; inset:0; z-index:-1` between the background blobs and the UI content.

## HTML (inside the background container)

```html
<svg class="grain" aria-hidden="true">
  <filter id="grain-filter">
    <feTurbulence type="fractalNoise" baseFrequency="0.7" numOctaves="3" stitchTiles="stitch"/>
    <feColorMatrix type="saturate" values="0"/>
  </filter>
  <rect width="100%" height="100%" filter="url(#grain-filter)"/>
</svg>
```

## CSS

```css
.grain {
  position: fixed;
  inset: 0;
  z-index: -1;          /* above blobs, below content */
  width: 100%;
  height: 100%;
  pointer-events: none; /* doesn't block clicks */
  opacity: 0.06;        /* start very subtle — 4%–8% typical */
  mix-blend-mode: overlay;
}
```

## Tuning

| Parameter | Effect | Range |
|-----------|--------|-------|
| `opacity` | Overall visibility | 0.03 (barely there) – 0.30 (heavy grain) |
| `baseFrequency` | Grain particle size | 0.7 (fine sand) – 0.2 (large clumps). Lower = larger. |
| `numOctaves` | Detail richness | 2 (simple) – 4 (rich, slower to render) |

Typical sweet spot for dark frosted-glass themes: `opacity: 0.06`, `baseFrequency: 0.7`.

## Pitfalls

- **Too subtle to see:** On high-DPI screens, opacity < 0.04 may become invisible. Bump to 0.06–0.08 minimum.
- **Overlay blend invisible on pure black:** `mix-blend-mode: overlay` needs some colour underneath. If the background is solid #000, switch to `soft-light` or bump opacity.
- **Scale via transform breaks edge coverage:** `transform: scale(2)` on a 100vw×100vh fixed element causes overflow. Instead, reduce `baseFrequency` (half the frequency = 2× the grain size).
- **`prefers-reduced-motion`:** Noise is static (no animation) — naturally compatible. No extra rule needed.
