# AI Inline-Analysis Pattern

Add LLM-powered analysis to individual items in an existing list/library UI — no page navigation, no modal overlay, just an expandable inline panel with loading state and toggle.

## When to use

- Existing project has a list/library of user content (sparks, notes, songs, snippets, etc.)
- User wants AI analysis/expansion on a single item: "untangle this thought", "summarize this note", "tag this song", "suggest related ideas"
- Result must stay in context — expand below the item, not navigate away
- Already have AI config (API_BASE / API_KEY / MODEL) wired up — reuse them

## Backend (Express endpoint)

```js
// Add after existing item endpoints, reuse existing AI vars
app.post('/api/items/:id/analyze', async (req, res) => {
  const { id } = req.params;

  if (!AI_API_KEY) {
    return res.status(400).json({ error: 'AI not configured' });
  }

  // Load item from storage
  const item = findItem(id);
  if (!item) return res.status(404).json({ error: 'Not found' });

  const aiResp = await fetch(`${AI_API_BASE}/chat/completions`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${AI_API_KEY}`
    },
    body: JSON.stringify({
      model: AI_MODEL,           // reuse env var, never hardcode
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user',   content: item.content }
      ],
      temperature: 0.7,
      max_tokens: 2000
    })
  });

  const data = await aiResp.json();
  const result = data.choices?.[0]?.message?.content || '';

  // Persist to item (include this from the start)
  if (!item.untangles) item.untangles = [];
  item.untangles.push({ result, created_at: new Date().toISOString() });
  fs.writeFileSync(ITEMS_FILE, JSON.stringify(items, null, 2), 'utf-8');

  res.json({ result, round: item.untangles.length });
});
```

Key points:
- Reuse existing `AI_API_BASE` / `AI_API_KEY` / `AI_MODEL` — no new env vars
- Return `{ result: "..." }` — client handles rendering
- Wrap in try/catch with clear error messages
- Don't persist the AI result (ephemeral display); re-fetch on each click

## Frontend (vanilla JS)

### Button placement

In the item builder function, add the button beside Edit/Delete:

```js
item.innerHTML = `
  <div class="item-main">...</div>
  <div class="item-actions">
    <button class="icon-btn" data-action="edit">Edit</button>
    <button class="icon-btn" data-action="delete">Del</button>
    <button class="icon-btn analyze-btn" data-action="analyze">Analyze</button>
  </div>
  <div class="item-edit-panel" style="display:none"></div>
`;

// Append results panel outside the flex row, below everything
const panel = document.createElement('div');
panel.className = 'item-analyze-panel';
panel.style.display = 'none';
item.appendChild(panel);
```

### Click handler (toggle + load)

```js
let loading = false;

analyzeBtn.addEventListener('click', async () => {
  if (loading) return;

  if (panel.style.display !== 'none') {
    // Collapse
    panel.style.display = 'none';
    analyzeBtn.textContent = 'Analyze';
    return;
  }

  // Expand + fetch
  loading = true;
  analyzeBtn.textContent = 'Analyzing…';
  analyzeBtn.disabled = true;
  panel.style.display = 'block';
  panel.innerHTML = '<div class="analyze-loading"><span class="spinner"></span>Analyzing…</div>';

  try {
    const r = await fetch(`/api/items/${item.id}/analyze`, { method: 'POST' });
    const data = await r.json();
    if (!r.ok) {
      panel.innerHTML = `<div class="analyze-error">${escapeHtml(data.error)}</div>`;
    } else {
      panel.innerHTML = renderResult(data.result);
    }
  } catch {
    panel.innerHTML = '<div class="analyze-error">Network error</div>';
  } finally {
    loading = false;
    analyzeBtn.textContent = 'Analyze';
    analyzeBtn.disabled = false;
  }
});
```

### Result rendering

For LLM output with `### Section` headings, convert to HTML:

```js
function renderResult(text) {
  return text.split('\n').map(line => {
    if (/^### (.+)/.test(line)) {
      return `<h3 class="analyze-h3">${escapeHtml(RegExp.$1)}</h3>`;
    }
    if (line.trim() === '') return '<br>';
    return `<p class="analyze-p">${escapeHtml(line)}</p>`;
  }).join('');
}
```

## CSS

Match existing design system — in a frosted-glass dark theme:

```css
/* Accent-colored button to distinguish from Edit/Del */
.analyze-btn {
  border-color: var(--accent);
  color: var(--accent);
}
.analyze-btn:hover { color: #fff; background: rgba(127,176,255,.20); }
.analyze-btn:disabled { opacity: .6; cursor: wait; pointer-events: none; }

/* Results panel: frosted glass (18px blur), scrollable */
.item-analyze-panel {
  width: 100%;
  margin-top: 12px;
  padding: 16px 18px;
  border-radius: 14px;
  background: var(--write);
  backdrop-filter: blur(18px) saturate(140%);
  border: 1px solid var(--line-soft);
  max-height: 480px;
  overflow-y: auto;
  font-size: 14px; line-height: 1.75;
}

/* Section headings in accent color */
.analyze-h3 {
  font-family: var(--font-display);
  font-weight: 600; font-size: 15px;
  color: var(--accent);
  margin: 18px 0 8px;
}
.analyze-h3:first-child { margin-top: 0; }

/* Body text in dim color */
.analyze-p { margin: 0 0 6px; color: var(--ink-dim); }

/* Loading spinner */
.analyze-loading { display: flex; align-items: center; gap: 10px; color: var(--ink-dim); }
.spinner {
  width: 16px; height: 16px;
  border: 2px solid var(--line-soft);
  border-top-color: var(--accent);
  border-radius: 50%;
  animation: spin .7s linear infinite;
}
@keyframes spin { to { transform: rotate(360deg); } }

/* Error */
.analyze-error { color: #FF6F9C; font-size: 14px; }
```

### Flex layout fix

If the item uses `display: flex` (row) for main+actions, add `flex-wrap: wrap` so the full-width results panel breaks to its own line:

```css
.item-card { display: flex; flex-wrap: wrap; ... }
.item-analyze-panel { flex-basis: 100%; }
```

## Pitfalls

- **Don't block the UI during fetch.** Use async/await with the button disabled + spinner shown. Multiple rapid clicks should be no-ops.
- **Persist results by default.** Always include the persisted variant (see below) — the user will ask for it every time if it's missing. Save results to an `untangles` (or equivalent) array on the item's JSON record, and restore the latest result on page load.
- **Escaping matters.** Use `escapeHtml()` on ALL user/AI text before injecting into innerHTML. LLM output can contain `<`, `>`, `&`.
- **Error states must be visible.** Show the error in the panel, not an alert(). The user needs to see what went wrong in context.
- **Reuse AI config, don't duplicate.** Use the existing `AI_MODEL` env var — never hardcode a model name in the endpoint. The user changes models by editing `.env`.

## Variant: Repeated calls (no toggle, every-click-fires)

When the user wants to call AI multiple times on the same item for fresh perspectives — every click fires a new request, the panel stays open, and results are replaced each time. No collapse toggle.

### Click handler changes

```js
let loading = false;
let roundCount = 0;  // session-only, resets on page refresh

analyzeBtn.addEventListener('click', async () => {
  if (loading) return;

  loading = true;
  roundCount++;
  analyzeBtn.textContent = `Analyzing… (${roundCount})`;
  analyzeBtn.disabled = true;
  panel.style.display = 'block';
  panel.innerHTML = `<div class="analyze-loading"><span class="spinner"></span>Analyzing… round ${roundCount}</div>`;

  try {
    const r = await fetch(`/api/items/${item.id}/analyze`, { method: 'POST' });
    const data = await r.json();
    if (!r.ok) {
      panel.innerHTML = `<div class="analyze-error">${escapeHtml(data.error)}</div>`;
    } else {
      // Prepend round counter, then render the result (covers previous)
      let html = `<div class="analyze-round-hint">Round ${roundCount}</div>`;
      html += renderResult(data.result);
      panel.innerHTML = html;
    }
  } catch {
    panel.innerHTML = '<div class="analyze-error">Network error</div>';
  } finally {
    loading = false;
    analyzeBtn.textContent = 'Analyze';
    analyzeBtn.disabled = false;
  }
});
```

Key differences from the toggle variant:
- **No collapse path** — the `if (panel.style.display !== 'none')` block is removed
- **`roundCount`** starts at 0, increments on each click, lives in the closure (page-refresh resets it to 0 — no persistence needed)
- **Results are replaced** (not appended) — each new call overwrites the panel content so only the latest result is visible
- **Round counter shown in loading state and result header** — user always knows which iteration they're looking at

### Round counter hint CSS

```css
.analyze-round-hint {
  font-family: var(--font-display);
  font-size: 11px; color: var(--ink-faint);
  letter-spacing: .5px;
  margin-bottom: 12px; padding-bottom: 8px;
  border-bottom: 1px dashed var(--line-soft);
}
```

### When to use each variant

- **Toggle** (default): \"analyze once, show/hide\" — good for deterministic outputs (tag suggestions, classifications, fixed-format summaries)
- **Repeated calls**: \"analyze with fresh randomness each click\" — good for creative/coaching use cases where the LLM's non-deterministic output (temperature > 0) produces different angles each time, and the user wants to explore multiple passes
- **Persisted repeated calls**: same as above but results persist to disk so they survive page refresh — the counter continues from where it left off, and the latest result auto-expands on page load. Use when the user values seeing their last session's analysis without re-running AI.

## Variant: Persisted repeated calls

Same as the repeated-calls variant above, but with persistence added.

### Backend changes

Save each result to the item's data before responding:

```js
// After AI response
if (!item.untangles) item.untangles = [];
const now = new Date().toISOString();
item.untangles.push({ result, created_at: now });
item.updated_at = now;
fs.writeFileSync(ITEMS_FILE, JSON.stringify(items, null, 2), 'utf-8');

// Return round number for frontend to sync counter
res.json({ result, round: item.untangles.length });
```

Data model (embedded in the item JSON):
```json
{
  "id": "...",
  "untangles": [
    { "result": "### Section...", "created_at": "2026-06-19T14:28:36.684Z" },
    { "result": "### Section...", "created_at": "2026-06-19T14:29:16.123Z" }
  ]
}
```

### Frontend changes

Three modifications to the repeated-calls variant:

**1. Initialize counter from saved data:**
```js
let roundCount = (item.untangles && item.untangles.length) || 0;
```

**2. Restore latest result on page load:**
```js
if (roundCount > 0) {
  const latest = item.untangles[roundCount - 1];
  panel.style.display = 'block';
  renderAnalysisResult(latest.result, roundCount);
}
```

**3. Sync counter from server response + update local cache:**
```js
// After successful fetch
roundCount = data.round;
if (!item.untangles) item.untangles = [];
item.untangles.push({ result: data.result, created_at: new Date().toISOString() });
renderAnalysisResult(data.result, data.round);
```

The `roundCount` from the server (`item.untangles.length`) is authoritative — this keeps the counter correct even if multiple sessions are modifying the same item.

### Old data compatibility

Old items won't have an `untangles` field. The backend handles this:
```js
if (!item.untangles) item.untangles = [];
```
And the frontend gracefully handles `roundCount === 0` (no panel shown, no restore attempted).
