# Tab-based SPA + Accordion (Vanilla JS)

Reusable frontend pattern for local web tools that need multiple modules in one page.

**Two navigation variants:**

| Variant | Class | Layout | Reference |
|---------|-------|--------|-----------|
| Top bar (classic) | `.tab` + `.tab-content` | Horizontal nav header | This doc |
| Left sidebar | `.sidebar-tab` + `.screen` | Sticky vertical nav | `references/sidebar-layout.md` |

Both use `is-active` state class and `data-screen` attribute. Choose based on
the design reference — the sidebar variant is documented separately.

## HTML structure (classic top-bar variant)

```html
<nav class="topbar">
  <button class="tab is-active" data-screen="diary">Diary</button>
  <button class="tab" data-screen="notes">Sparks</button>
</nav>

<main class="page">
  <section class="screen is-active" id="diary"><!-- module 1 --></section>
  <section class="screen" id="notes"><!-- module 2 --></section>
</main>
```

## Tab switching (JS) — classic top bar

```js
document.querySelectorAll('.tab').forEach(tab => {
  tab.addEventListener('click', () => {
    document.querySelectorAll('.tab').forEach(t => t.classList.remove('is-active'));
    document.querySelectorAll('.screen').forEach(s => s.classList.remove('is-active'));
    tab.classList.add('is-active');
    document.getElementById(tab.dataset.screen).classList.add('is-active');
    if (tab.dataset.screen === 'notes') loadNotes();
  });
});
```

## CSS for tabs (classic top bar)

```css
.tab { color: var(--ink-dim); border-bottom: 2px solid transparent; }
.tab.is-active { color: var(--ink); border-bottom-color: var(--accent); }
.screen { display: none; }
.screen.is-active { display: block; animation: fadeup .5s ease both; }
```

## Accordion pattern (expand/collapse list items)

Each item: a clickable header that toggles `.expanded` on the parent, revealing a body with full content + inline actions.

```html
<div class="frag-item">
  <div class="frag-header">
    <span class="expand-icon">▸</span>
    <span class="frag-cat-tag cat-copy-sparks">Copy Sparks</span>
    <span class="frag-preview">Preview text...</span>
    <span class="frag-date">06-10 18:44</span>
  </div>
  <div class="frag-body">
    <div class="frag-full-content">Full content here</div>
    <div class="notes-section"><!-- nested CRUD --></div>
  </div>
</div>
```

```js
header.addEventListener('click', () => item.classList.toggle('expanded'));
```

```css
.frag-body { display: none; }
.frag-item.expanded .frag-body { display: block; }
.expand-icon { transition: transform 0.2s; }
.frag-item.expanded .expand-icon { transform: rotate(90deg); }
```

## Nested CRUD inside accordion (notes on a list item)

Each accordion body contains a form to append sub-items. The "Add Note" button stops event propagation to prevent accordion toggle:

```js
addBtn.addEventListener('click', async (e) => {
  e.stopPropagation();
  const text = textarea.value.trim();
  if (!text) return;
  await fetch(`/api/fragments/${frag.id}/notes`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ text })
  });
  await loadFragments();  // full refresh for simplicity
});
```

## Inline delete button on accordion header

Place a small `×` button at the end of the header. It must `stopPropagation()` so clicking it doesn't also toggle the accordion. Confirm before deleting, then refresh the list.

HTML (insert inside `.frag-header`):
```html
<button class="frag-delete-btn" title="删除">×</button>
```

```js
const delBtn = item.querySelector('.frag-delete-btn');
delBtn.addEventListener('click', async (e) => {
  e.stopPropagation();  // don't toggle accordion
  if (!confirm('Delete this item? This cannot be undone.')) return;
  await fetch(`/api/fragments/${frag.id}`, { method: 'DELETE' });
  await loadFragments();
});
```

```css
.frag-delete-btn {
  background: none;
  border: none;
  color: #ccc;
  font-size: 18px;
  cursor: pointer;
  padding: 0 4px;
  line-height: 1;
  flex-shrink: 0;
  transition: color 0.15s;
}
.frag-delete-btn:hover {
  color: #c0392b;
}
```

## Category tags with distinct colors

Use class-based color mapping for a fixed set of categories:

```css
.frag-cat-tag.cat-copy-sparks  { background: rgba(45,130,240,.20); color: #7FB0FF; }
.frag-cat-tag.cat-wild-ideas   { background: rgba(248,113,113,.20); color: #f87171; }
.frag-cat-tag.cat-golden-lines { background: rgba(47,215,166,.20); color: #5BE3C0; }
.frag-cat-tag.cat-mood         { background: rgba(255,178,107,.20); color: #FFB26B; }
```

```html
<span class="frag-cat-tag cat-golden-lines">Golden Lines</span>
```

The class name follows `cat-<value>` where value matches the `data-cat` attribute and the server-side `VALID_CATEGORIES` enum.
