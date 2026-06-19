# Filterable Library with Inline Edit

Reusable pattern for a data-list panel with filter pills, sort dropdown,
group-by toggle, and per-item inline editing — all in dark frosted glass style.

## When to use

- User wants a "library" or "directory" view of saved items
- Requirements include: category filter, multi-field sort, group-by toggle
- Each item needs inline Edit/Delete (not navigating away)
- Items have: title, content preview, category chip, timestamp, action buttons

## HTML structure

```html
<!-- Library panel (below whatever creates the items) -->
<div class="panel" id="libraryPanel">
  <!-- Control bar -->
  <div class="library-controls">
    <div class="pills" id="libFilterPills">
      <button class="pill is-active" data-filter="all">All</button>
      <button class="pill" data-filter="cat-a">Category A</button>
      <button class="pill" data-filter="cat-b">Category B</button>
    </div>
    <div class="library-controls-right">
      <select class="sort-select" id="libSortSelect">
        <option value="newest">Newest first</option>
        <option value="oldest">Oldest first</option>
        <option value="title-asc">Title A–Z</option>
      </select>
      <label class="toggle-label">
        <input type="checkbox" id="libGroupToggle">
        <span class="toggle-track"></span>
        <span>Group by tag</span>
      </label>
    </div>
  </div>
  <div class="library-list" id="libraryList">
    <p class="hint">No items yet.</p>
  </div>
</div>
```

## JS: state management

Keep filter/sort/group state as module-level variables:

```js
let libFilter = 'all';
let libSort = 'newest';
let libGrouped = false;
let allItems = [];

function renderLibrary() {
  let filtered = allItems;
  if (libFilter !== 'all') filtered = allItems.filter(i => i.category === libFilter);

  if (libSort === 'oldest') {
    filtered = [...filtered].sort((a, b) => a.created_at.localeCompare(b.created_at));
  } else if (libSort === 'title-asc') {
    filtered = [...filtered].sort((a, b) =>
      getTitle(a).localeCompare(getTitle(b), 'en', { sensitivity: 'base' }));
  } else {
    filtered = [...filtered].sort((a, b) => b.created_at.localeCompare(a.created_at));
  }

  if (libGrouped) renderGrouped(filtered);
  else renderFlat(filtered);
}
```

## JS: group mode

```js
function renderGrouped(items) {
  const groups = {};
  for (const item of items) {
    if (!groups[item.category]) groups[item.category] = [];
    groups[item.category].push(item);
  }

  const order = ['cat-a', 'cat-b', 'cat-c'];
  for (const cat of order) {
    if (!groups[cat] || groups[cat].length === 0) continue;

    const group = document.createElement('div');
    group.className = 'spark-group';
    group.innerHTML = `
      <div class="spark-group-header">
        <span class="group-expand-icon">▾</span>
        <span class="frag-cat-tag cat-${cat}">${catLabel(cat)}</span>
        <span class="spark-group-count">· ${groups[cat].length}</span>
      </div>
      <div class="spark-group-items"></div>
    `;

    const container = group.querySelector('.spark-group-items');
    groups[cat].forEach(item => container.appendChild(buildItem(item)));

    group.querySelector('.spark-group-header').addEventListener('click', () => {
      group.classList.toggle('collapsed');
    });

    libraryEl.appendChild(group);
  }
}
```

## JS: inline edit panel

```js
let editingId = null;

function startEdit(itemEl, item) {
  editingId = item.id;
  const panel = itemEl.querySelector('.edit-panel');
  panel.innerHTML = `
    <div class="edit-row">
      <select class="edit-select">/* category options */</select>
      <input class="field" value="${escapeHtml(item.title || '')}" placeholder="Title">
    </div>
    <textarea class="area">${escapeHtml(item.content)}</textarea>
    <div class="edit-actions">
      <button class="edit-save-btn">Save</button>
      <button class="edit-cancel-btn">Cancel</button>
    </div>
  `;
  panel.style.display = 'flex';

  panel.querySelector('.edit-save-btn').addEventListener('click', async () => {
    // PUT to API, then cancelEdit + reload
  });
  panel.querySelector('.edit-cancel-btn').addEventListener('click', () => cancelEdit(itemEl));
}

function cancelEdit(itemEl) {
  editingId = null;
  itemEl.querySelector('.edit-panel').style.display = 'none';
  itemEl.querySelector('[data-action="edit"]').textContent = 'Edit';
}
```

## Pitfalls

### Capture pills vs library filter pills must be independent
If the same page has both a "create" section with category pills and the library
with filter pills, they MUST use separate DOM containers and separate JS state.
The capture pills set `selectedCategory`; the library pills set `libFilter`.
They must not interfere.

### Group mode needs matching CSS for collapse
The `.spark-group.collapsed .spark-group-items { display: none; }` rule is
essential. Also animate the expand icon: `transform: rotate(-90deg)` when collapsed.

### Sort must not mutate the source array
Always spread: `[...filtered].sort(...)`. Mutating `allItems` causes bugs when
switching between sort modes.

### Title fallback
When items have an optional title, `getTitle()` should fall back to the first
line of content (truncated to ~60 chars). Never show empty titles.

### Edit panel notes
If items have a notes/comment sub-system, include it INSIDE the edit panel —
users expect to see all item data when editing, not just the main fields.
