# Dual-Panel AI Annotation Pattern

Use this when adding a **detail-view page** where the user sees their content in an editable area on one side and AI-generated annotations/batch-notes on the other — like a writing coach, editor, or reviewer that gives structural feedback without rewriting the text.

## When to use

Triggers: "AI batch annotations", "writing coach side panel", "structural feedback alongside text", "Polish button", or adding a new module to an existing multi-screen SPA where the core flow is: click item → detail view → AI annotates → user edits in response.

## Architecture

```
Screen (new .screen section)
├── Create Panel      ← title + textarea + save (like Sparks capture)
├── List Panel
│   ├── List State    ← clickable cards (title, preview, time)
│   └── Detail State  ← two-column grid
│       ├── Left: Editor Column
│       │   ├── Title input
│       │   ├── Full-text textarea (editable)
│       │   └── Action row: Save Changes | Polish | Delete
│       └── Right: Annotations Column (sticky)
│           ├── Empty hint ("Click Polish for feedback")
│           └── Annotations content (populated by AI)
```

## Key design decisions

### Side-by-side, not expand-below

Unlike the inline untangle pattern (expand below list item), this uses a two-column CSS Grid so the user sees text AND annotations simultaneously. The annotations column uses `position: sticky` to stay visible while scrolling long text.

```css
.polish-detail-layout {
  display: grid;
  grid-template-columns: 1fr 340px;
  gap: 16px;
  align-items: start;
}
```

### Annotations persist by default (cross-session recall)

Unlike earlier guidance, **always persist annotations** to the entry's JSON data. The user consistently wants to revisit previous AI feedback after a refresh.

Data model (append to entry):
```json
{
  "id": "...",
  "annotations": [
    { "annotations": "...", "created_at": "..." }
  ]
}
```

Backend: after AI response, save to the entry before responding:
```js
if (!entry.annotations) entry.annotations = [];
entry.annotations.push({ annotations, created_at: new Date().toISOString() });
fs.writeFileSync(POLISH_FILE, JSON.stringify(entries, null, 2), 'utf-8');
res.json({ annotations, round: entry.annotations.length });
```

Frontend: on `openPolishDetail()`, restore latest saved annotations and set counter:
```js
polishAnnotateCount = (entry.annotations && entry.annotations.length) || 0;
if (polishAnnotateCount > 0) {
  const latest = entry.annotations[polishAnnotateCount - 1];
  renderPolishAnnotations(latest.annotations, polishAnnotateCount);
}
```

Each click increments the round counter shown as `"本批注第 N 次"`, and the latest result replaces the previous display (cover mode — same as untangle persistence pattern in `references/ai-inline-analysis.md`).

### Polish button calls the current editor content

The annotate endpoint receives the entry's stored content from the server (NOT the client-side textarea value), so it annotates the last-saved version. If the user edited but hasn't saved, the old version is annotated — which is intentional: save first, then get feedback. To annotate the latest draft, the user saves then clicks Polish.

## Server endpoint pattern

```js
// ─── POST /api/polish/:id/annotate ───
app.post('/api/polish/:id/annotate', async (req, res) => {
  // 1. Check API key
  // 2. Load entry from file by ID
  // 3. Build system prompt (structural editor, no rewriting)
  // 4. Call AI with entry.content as user message
  // 5. Return { annotations: "..." }
});
```

## System prompt for structural editing

The prompt role: a writing coach/editor who gives STRUCTURAL feedback only — no rewriting, no word-choice "improvements". Key constraints:

1. Only comment on: paragraph order, repetition/redundancy, logical gaps, hook strength, ending impact
2. Never output rewritten sentences or "suggested alternatives"
3. Never "optimize" the author's word choices or tone
4. Reference specific paragraphs/sentences for easy location
5. Ban AI-cliché sentence patterns ("不是…而是…", "其实…", etc.)
6. Write like a real human editor, not a template

## Frontend interaction pattern

```
polishAnnotateBtn click →
  disable button, show "Analyzing…"
  replace annotations panel with spinner
  fetch POST /api/polish/:id/annotate
  on success: parse response into paragraphs, render in panel
  on error: show error in panel
  re-enable button
```

Use existing `.untangle-spinner` and `.untangle-error` classes for consistency (shared between untangle and polish features).

## Adding a new page to existing multi-screen SPA

When adding a 4th (or Nth) screen to an existing project:

1. **HTML:** Add `<button class="sidebar-tab" data-screen="polish">` in sidebar, add `<section class="screen" id="polish">` before `</main>`
2. **JS:** Extend `themeMap` with `polish: 'theme-polish'`, add `loadPolishList()` hook in tab-switching `if/else`
3. **CSS:** Add `body.theme-polish { --c1/--c2/--accent }`, add module-specific styles, add responsive overrides
4. **Server:** Add CRUD endpoints + AI endpoint after existing modules, create data directory with `fs.mkdirSync`

Theme color choice: for a "polish/refinement" concept, warm gold/amber works well:
```css
body.theme-polish { --c1:#FFD54F; --c2:#FFAB40; --accent:#FFE082; }
```

## Pitfalls

### Annotations panel overflows on long AI responses

Set `max-height: 480px` and `overflow-y: auto` on the annotations column. Add custom scrollbar styling matching the dark theme.

### Two-column breaks on mobile

In the responsive `@media (max-width: 768px)` section, collapse to single column:
```css
.polish-detail-layout { grid-template-columns: 1fr; }
.polish-annotations-col { position: static; max-height: 360px; }
```

### User expects annotations to persist

Always persist by default (see above). Both the inline-analysis and dual-panel patterns should save results to the item's JSON record. The user will always ask for it if it's missing — build it in from the start.
