# Aurora Video Background

Replace procedural backgrounds (SVG fog, CSS gradients, drifting orbs) with a looping MP4 video as the full-page background. Dark theme, one video across all tabs/views.

## HTML

```html
<div class="scene" aria-hidden="true">
  <!-- TODO: replace src with actual video path -->
  <video class="bg-video" autoplay muted loop playsinline
         poster="assets/aurora-still.jpg">
    <source src="assets/aurora.mp4" type="video/mp4">
  </video>
  <!-- Still fallback for reduced-motion -->
  <img class="bg-still" src="assets/aurora-still.jpg" alt="">
  <!-- Dark overlay for readability -->
  <div class="bg-overlay"></div>
</div>
```

Key attributes on `<video>`:
- `autoplay muted loop playsinline` — no sound, seamless loop, works on mobile
- `poster` — shown while video loads
- `aria-hidden="true"` — decorative, not interactive

## CSS

```css
.scene {
  position: fixed; inset: 0; z-index: -2; overflow: hidden;
  background: #060610;  /* fallback while video loads */
}

.bg-video {
  position: absolute; inset: 0;
  width: 100%; height: 100%;
  object-fit: cover;
  pointer-events: none;
}

.bg-still {
  display: none;  /* hidden by default, shown by reduced-motion */
  position: absolute; inset: 0;
  width: 100%; height: 100%;
  object-fit: cover;
  pointer-events: none;
}

.bg-overlay {
  position: absolute; inset: 0;
  background: rgba(0,0,0,0.48);  /* tune for readability */
  pointer-events: none;
}
```

**Overlay tuning:** Start at `0.48`. Go darker (0.55) if text fights the video; lighter (0.40) if the video is dim. The overlay must keep text at full contrast without crushing the video's glow.

## Reduced Motion

```css
@media (prefers-reduced-motion: reduce) {
  .bg-video { display: none; }
  .bg-still { display: block; }
}
```

The still image replaces the video completely — no movement, no frame decoding.

## Stacking Order

```
z-index -2: .scene (video + still + overlay)
z-index  1: panel children (relative)
z-index 20: sidebar (sticky)
```

All background elements have `pointer-events: none` so they never intercept clicks.

## Theme Colors

When the video is the universal background across tabs, keep theme-specific color differences **only on accent elements** (buttons, navigation highlights, indicator bar). Remove theme-dependent background layers — the video serves all tabs.

```css
/* Keep these — they only affect UI chrome */
body.theme-diary  { --c1:#FFB26B; --c2:#FF6F9C; --accent:#FFC089; }
body.theme-notes  { --c1:#2FD7A6; --c2:#2FC0D9; --accent:#5BE3C0; }
body.theme-songs  { --c1:#4D9FFF; --c2:#6E7CFF; --accent:#7FB0FF; }
```

## File Placement

User places their own video/still image:
```
project/
└── public/
    └── assets/
        ├── aurora.mp4        ← user replaces
        └── aurora-still.jpg  ← user replaces
```

Always use placeholder paths with a `TODO` comment so the user knows where to put their assets.
