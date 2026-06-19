# SVG Fractal Fog Background

Multi-layer procedural fog/mist via SVG `feTurbulence` (fractalNoise) + `feColorMatrix` — no external images. Fog is the main visual element with faint coloured orbs behind it.

## When to use

- You want a dreamy, misty atmosphere where fog is the dominant background element
- You want slow, subtle drift animation (≥30s cycle)
- You want coloured orbs/lights behind the fog as barely-visible atmosphere, not the main visual
- Pure CSS+SVG, no canvas, no WebGL, no external assets

## Concept

Two layers of `feTurbulence` at different scales, both mapped to cool pale tones via `feColorMatrix`, masked with an off-centre radial gradient so fog is strongest in the centre ~third and fades toward edges. Slow CSS `transform` animation creates mist-like drift.

## HTML structure

```html
<div class="scene" aria-hidden="true">
  <!-- Layer 1: Faint coloured orbs (behind fog) -->
  <div class="orb-layer ..."><div class="blob ...">×N</div></div>
  
  <!-- Layer 2: SVG fog (main visual) -->
  <div class="fog-container" aria-hidden="true">
    <svg class="fog-svg" xmlns="http://www.w3.org/2000/svg" 
         viewBox="0 0 1600 1200" preserveAspectRatio="xMidYMid slice">
      <defs>
        <!-- Wide fog: low frequency, big sweeping masses -->
        <filter id="fogWide">
          <feTurbulence type="fractalNoise" baseFrequency="0.012" 
                        numOctaves="3" seed="5" result="turb"/>
          <feColorMatrix type="matrix" in="turb"
            values="0 0 0 0 0.78
                    0 0 0 0 0.82
                    0 0 0 0 0.88
                    1 0 0 0 0"/>
        </filter>
        <!-- Detail fog: higher frequency, wispy texture -->
        <filter id="fogDetail">
          <feTurbulence type="fractalNoise" baseFrequency="0.022" 
                        numOctaves="4" seed="12" result="turb"/>
          <feColorMatrix type="matrix" in="turb"
            values="0 0 0 0 0.80
                    0 0 0 0 0.84
                    0 0 0 0 0.90
                    0.75 0 0 0 0.05"/>
        </filter>
        <!-- Fog strength mask: strongest near centre, irregular ellipse -->
        <radialGradient id="fogMask" cx="52%" cy="44%" r="42%" 
                        fx="44%" fy="38%">
          <stop offset="0%"   stop-color="#fff" stop-opacity="1"/>
          <stop offset="55%"  stop-color="#fff" stop-opacity="0.85"/>
          <stop offset="78%"  stop-color="#fff" stop-opacity="0.45"/>
          <stop offset="100%" stop-color="#fff" stop-opacity="0.08"/>
        </radialGradient>
      </defs>
      <!-- Two fog layers with different drift speeds -->
      <g class="fog-drift fog-drift--slow">
        <rect x="-200" y="-200" width="2000" height="1600"
              filter="url(#fogWide)" mask="url(#fogMask)"
              style="mix-blend-mode:screen;opacity:0.65"/>
      </g>
      <g class="fog-drift fog-drift--med">
        <rect x="-160" y="-160" width="1920" height="1520"
              filter="url(#fogDetail)" mask="url(#fogMask)"
              style="mix-blend-mode:screen;opacity:0.55"/>
      </g>
    </svg>
  </div>
</div>
```

## CSS

```css
/* Fog container — absolute, behind content, no clicks */
.fog-container {
  position: absolute; inset: 0;
  pointer-events: none;
  overflow: hidden;
}
/* SVG is 110% to allow animation margin without revealing edges */
.fog-svg {
  position: absolute;
  width: 110%; height: 110%;
  top: -5%; left: -5%;
}
/* Slow drift — 30s+ cycle, ease-in-out alternate for mist-like flow */
.fog-drift--slow { animation: fogSlide 38s ease-in-out infinite alternate; }
.fog-drift--med  { animation: fogSlide2 32s ease-in-out infinite alternate; }

@keyframes fogSlide {
  0%   { transform: translate(0, 0); }
  33%  { transform: translate(3%, -2%); }
  66%  { transform: translate(-2%, 3%); }
  100% { transform: translate(1%, -1%); }
}
@keyframes fogSlide2 {
  0%   { transform: translate(0, 0); }
  33%  { transform: translate(-3%, 1%); }
  66%  { transform: translate(2%, -3%); }
  100% { transform: translate(-1%, 2%); }
}

/* Reduced motion: freeze fog */
@media (prefers-reduced-motion: reduce) {
  .fog-drift--slow,
  .fog-drift--med  { animation: none !important; }
}
```

## feColorMatrix explained

The turbulence filter outputs the same noise value in all 4 channels (R, G, B, A). The matrix remaps them:

- **Rows 1–3 (RGB):** All zeros in columns 1–4 → constant colour. Values in column 5 are the RGB of that constant (the fog tint). Cool pale blue-gray: R=0.78, G=0.82, B=0.88.
- **Row 4 (Alpha):** `1 0 0 0 0` → copies R-channel noise directly as alpha. Fog opacity varies across the viewport based on the noise pattern.
- **Detail fog variant:** `0.75 0 0 0 0.05` → dampened alpha (×0.75) with a slight floor (+0.05), giving softer, wispier fog.

## Tuning

| Parameter | Effect | Notes |
|-----------|--------|-------|
| `baseFrequency` | Fog scale | 0.008–0.015 = huge masses; 0.02–0.04 = finer wisps |
| `numOctaves` | Detail richness | 3–4 typical. 5+ gets expensive on low-end GPUs |
| `seed` | Pattern shape | Different per layer so they don't align |
| Colour matrix column 5 | Fog tint | Higher = brighter/more opaque. Keep RGB close together for neutral tint; boost B slightly for cool tone |
| Mask `r` | Fog spread radius | 35–50% of viewBox. Smaller = more contained fog patch |
| Mask `fx`/`fy` | Focal offset | Off-centre creates irregular feel |
| `opacity` on rect | Layer intensity | 0.4–0.7 typical. Stack two layers at 0.65 + 0.55 |
| `mix-blend-mode` | Blending with orbs | `screen` keeps fog luminous. `normal` for opaque fog |

## How coloured orbs work behind fog

The orbs use the same `mix-blend-mode: screen` at very low opacity (15–20%). The fog above them also uses `screen` — this stacks naturally: dark background → faint coloured glow → pale fog on top. The fog's pale blue-gray mixes with whatever colour bleeds through from below, creating the "fog lit by coloured light" effect.

**Theme switching:** Change the orb colours via CSS custom properties; fog stays constant (cool pale tone works with any colour scheme). Orb opacity transitions (1.2s ease) create a smooth colour shift while the fog remains stable.

## Pitfalls

- **Edge banding:** If the SVG is exactly 100% and you animate `transform`, edges of the SVG become visible. Fix: make SVG 110% with -5% offset so the 5% overflow margin is always off-screen.
- **`feColorMatrix` type="matrix" column order:** The 20 values are read column-major (column 1 = R input, column 2 = G input, column 3 = B input, column 4 = A input, column 5 = offset/add). This is NOT row-major. Double-check your matrix.
- **Fog invisible on light backgrounds:** This technique assumes a near-black background (`#07070F` or similar). On light themes, invert the colour matrix values (set RGB to dark tones like 0.10–0.15) and use `mix-blend-mode: multiply`.
- **GPU strain:** Two full-viewport `feTurbulence` filters with 3–4 octaves each are moderately expensive. On low-power devices (phones, old laptops), drop the detail layer or reduce octaves to 3 on both. Test on the slowest target device.
- **Responsive fog:** The `radialGradient` mask uses percentage coordinates (cx, cy, r) relative to `viewBox` — it scales naturally. The SVG's `preserveAspectRatio="xMidYMid slice"` ensures it fills any viewport without stretching.
- **SVG filter bounds:** Default `x="-10%" y="-10%" width="120%" height="120%"`. For heavy blur/feTurbulence that bleeds beyond the element boundary, set explicit `x="0%" y="0%" width="100%" height="100%"` — otherwise the filter may clip.
