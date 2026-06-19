# Theme / Design Migration from Standalone Reference

When the user provides a standalone HTML file as a visual design reference and asks
you to apply it to an existing local web tool project.

## Trigger

User attaches or points to a `.html` file that is a pure visual reference
(no backend, no real data), and says "apply this theme to the project" or similar.

## Workflow

1. **Read the reference fully.** Don't skim — read every line of CSS, HTML structure,
   and any demo JS. Understand the design system: color variables, component classes,
   layout grid, responsive breakpoints, animation/transition preferences.

2. **Identify the design tokens.** The reference will have CSS custom properties
   (or hardcoded values) that define the visual language:
   - Colors (background, text, accent, muted, border)
   - Spacing / border-radius scale
   - Font stack
   - Glass/panel effects (backdrop-filter, shadows, gradients)
   - Per-section theme variants (e.g., different color schemes per tab)

3. **Map old → new class names.** Make a mental table:
   - Old `.selected` → New `.is-selected`
   - Old `.tab-content.active` → New `.screen.is-active`
   - Old `.cat-btn` → New `.pill`
   - etc.

   Be consistent — the reference uses a naming convention (like BEM-lite with
   `is-` state prefixes). Adopt it everywhere.

4. **Rewrite in order: CSS → HTML → JS.** Never change JS class references
   before the CSS and HTML agree on the new names.

   - **CSS:** Write the complete new stylesheet. Start with the reference CSS
     as base, then extend with all the missing components the reference didn't
     show (edit panels, notes, error messages, empty states, etc.). Match the
     reference's design language exactly.

   - **HTML:** Restructure DOM to match the reference's markup pattern.
     Preserve ALL existing `id` and `data-*` attributes that JS depends on.
     Remove any CSS framework link (Pico.css, Bootstrap) that would conflict.

   - **JS:** Update class name strings in selectors, toggle logic, and
     innerHTML templates. The reference may use different DOM nesting — update
     event delegation selectors accordingly (e.g., `.closest('.pill')` instead
     of `.closest('.cat-btn')`).

5. **Verify end-to-end.** Start the server and test:
   - Page loads, CSS and JS files served correctly
   - All tabs switch and background theme transitions work
   - All CRUD operations (create, read, update, delete) still function
   - Empty states render correctly
   - Error messages display properly
   - Responsive layout at narrow widths

## Pitfalls

### Follow-up: i18n after theme migration

A common sequence is theme migration → i18n (change all text to another
language). This has its own 7-layer checklist — see `references/i18n-checklist.md`.
The i18n pass touches MORE layers than the theme pass (data model, AI prompts,
stored JSON values) and missing any one breaks the tool.

### CSS framework conflict
The old project may use a CSS framework (Pico.css, Bootstrap). Remove the
`<link>` tag entirely — the new theme is self-contained and frameworks will
override your custom styles unpredictably.

### Class name mismatch between CSS and JS
If you rename `.selected` to `.is-selected` in CSS but forget to update
`element.classList.add('selected')` in JS, the visual state won't show.
This is the most common bug — do a global search in app.js for every class
name you changed in CSS.

### Missing component styles
The reference HTML is a static demo. It won't have styles for:
- Edit panels / inline forms
- Error message states
- Empty state placeholders
- Delete confirmation flows
- Dynamic content (varying text lengths)

For each missing component, design new styles that match the reference's
visual language. Use the same `var(--name)` tokens, same border-radius scale,
same backdrop-filter glass effect, same color palette.

### Background animation performance
Animated background orbs/blobs use `filter: blur()` and `mix-blend-mode`.
These are GPU-intensive. Include `@media (prefers-reduced-motion: reduce)`
to disable animations for accessibility.

### Color-mix() browser support
`color-mix(in srgb, ...)` is well-supported in modern browsers (Chrome 111+,
Firefox 113+, Safari 16.2+). It's fine for a personal local tool, but if
the user mentions cross-browser concerns, fall back to `rgba()` or CSS
variables with opacity.
