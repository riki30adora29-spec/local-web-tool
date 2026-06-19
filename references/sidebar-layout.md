# Sidebar Layout — Vertical Sticky Nav + Sliding Indicator

Reusable pattern for replacing a horizontal topbar with a fixed left sidebar
that has a smooth-sliding active indicator. Works on both desktop (vertical)
and mobile (horizontal top bar).

## When to use

- User asks for "left sidebar navigation" or "vertical nav instead of top bar"
- Design reference shows sidebar-style navigation
- Tab count is small (3–5 items) — long lists don't fit well in a sticky sidebar

## HTML structure

```html
<aside class="sidebar">
  <div class="sidebar-indicator"></div>

  <button class="sidebar-tab is-active" data-screen="diary">Diary</button>
  <button class="sidebar-tab" data-screen="notes">Sparks</button>
  <button class="sidebar-tab" data-screen="songs">♪ Playlist</button>

  <div class="sidebar-spacer"></div>
  <button class="btn btn-ghost sidebar-export" id="exportBtn">Export All</button>
</aside>
```

Key elements:
- `.sidebar-indicator` — empty div, absolutely positioned, CSS transition on `top`/`height` (desktop) or `left`/`width` (mobile)
- `.sidebar-tab` — replaces old `.tab`, uses `data-screen` instead of `data-tab`
- `.sidebar-spacer` — pushes the export button to the bottom
- `.sidebar-export` — optional action button pinned at bottom

## CSS: desktop (vertical sidebar)

```css
body {
  display: flex;          /* sidebar + content side by side */
  min-height: 100vh;
}

.sidebar {
  width: 220px;
  flex-shrink: 0;
  position: sticky;
  top: 0;
  height: 100vh;
  z-index: 20;
  display: flex;
  flex-direction: column;
  padding: 24px 16px;
  background: rgba(10,9,18,.55);
  backdrop-filter: blur(22px) saturate(150%);
  border-right: 1px solid var(--line-soft);
}

.sidebar-indicator {
  position: absolute;
  left: 0;
  width: 3px;
  border-radius: 0 2px 2px 0;
  background: linear-gradient(180deg, var(--c1), var(--c2));
  box-shadow: 0 0 14px color-mix(in srgb, var(--c2) 50%, transparent);
  transition: top 0.35s cubic-bezier(0.4, 0, 0.2, 1),
              height 0.35s cubic-bezier(0.4, 0, 0.2, 1);
}

.sidebar-tab {
  appearance: none; border: 0; background: transparent;
  font: inherit; font-size: 18px; font-weight: 400;
  color: var(--ink-dim);
  padding: 14px 16px;
  margin: 2px 0;
  border-radius: 14px;
  text-align: left;
  cursor: pointer;
  transition: color .25s, background .25s, transform .2s;
}

.sidebar-tab:hover {
  color: var(--ink);
  background: var(--clear-hover);
  transform: translateX(3px);    /* subtle slide-right on hover */
}

.sidebar-tab.is-active {
  color: var(--ink);
  font-weight: 500;
}

.sidebar-spacer { flex: 1; }

/* Main content scrolls independently */
.page {
  flex: 1;
  overflow-y: auto;
  height: 100vh;
  padding: clamp(20px,4vw,48px);
}
```

## JS: sliding indicator

The indicator position is calculated from the active tab's `offsetTop`/`offsetHeight` (desktop) or `offsetLeft`/`offsetWidth` (mobile). The CSS transition handles the animation.

```js
const sidebarTabs = document.querySelectorAll('.sidebar-tab');
const sidebarIndicator = document.querySelector('.sidebar-indicator');

function isMobile() { return window.innerWidth <= 768; }

function updateSidebarIndicator() {
  const active = document.querySelector('.sidebar-tab.is-active');
  if (!active || !sidebarIndicator) return;

  if (isMobile()) {
    sidebarIndicator.style.top = '';
    sidebarIndicator.style.height = '';
    sidebarIndicator.style.left = active.offsetLeft + 'px';
    sidebarIndicator.style.width = active.offsetWidth + 'px';
  } else {
    sidebarIndicator.style.left = '';
    sidebarIndicator.style.width = '';
    sidebarIndicator.style.top = active.offsetTop + 'px';
    sidebarIndicator.style.height = active.offsetHeight + 'px';
  }
}

// Wire up tab clicks
sidebarTabs.forEach(tab => {
  tab.addEventListener('click', () => {
    sidebarTabs.forEach(t => t.classList.remove('is-active'));
    tab.classList.add('is-active');
    updateSidebarIndicator();
    // ... screen switching logic ...
  });
});

// Recalculate on resize (switches between vertical/horizontal modes)
window.addEventListener('resize', updateSidebarIndicator);

// Initial positioning
updateSidebarIndicator();
```

## CSS: responsive (≤768px)

On narrow screens, the sidebar collapses to a horizontal top bar:

```css
@media (max-width: 768px) {
  body { flex-direction: column; }

  .sidebar {
    width: 100%;
    height: auto;
    position: sticky;
    flex-direction: row;       /* horizontal tabs */
    align-items: center;
    gap: 6px;
    padding: 10px 14px;
    border-right: none;
    border-bottom: 1px solid var(--line-soft);
  }

  .sidebar-indicator {
    /* Switch to horizontal bar at the bottom */
    left: auto; bottom: 0;
    width: auto; height: 3px;
    border-radius: 2px 2px 0 0;
    transition: left 0.35s cubic-bezier(0.4, 0, 0.2, 1),
                width 0.35s cubic-bezier(0.4, 0, 0.2, 1);
  }

  .sidebar-tab {
    font-size: 14px;
    padding: 8px 14px;
    margin: 0;
    flex-shrink: 0;
  }

  .sidebar-tab:hover { transform: none; }  /* disable X shift */

  .page {
    height: auto;
    overflow-y: visible;
    padding: 20px 14px;
  }
}
```

## Pitfalls

### Indicator stuck at origin on page load
The indicator's `top`/`left` starts at 0 (CSS default). Call `updateSidebarIndicator()` during init and after the DOM is ready. If tabs are rendered dynamically (e.g., after an API call), call it after the render completes.

### Indicator doesn't move on resize
The desktop/mobile breakpoint switches the indicator between `top`/`height` and `left`/`width` modes. You MUST clear the unused properties when switching modes — otherwise the old values persist and the indicator appears in the wrong place.

### Tab selector name collision
If your old code uses `.tab` and the sidebar uses `.sidebar-tab`, do a global search to ensure no stray `.tab` selectors remain. Mixing them causes silent failures (tabs don't highlight, indicator doesn't move).

### `offsetTop` returns 0
This happens if the sidebar or parent has `display: none` at calculation time. Ensure the sidebar is visible before calling `updateSidebarIndicator()`. Call it after `.is-active` is added, not before.
