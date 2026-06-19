# i18n Checklist — Local Web Tools

When the user asks to change all text in a local web tool from one language
to another (e.g., Chinese → English), follow this checklist. Missing any
layer breaks either the UI, the API, the data model, or the LLM integration.

## Full checklist (7 layers)

### 1. HTML: UI text
- `<title>`, tab names, button labels, placeholders, hints/empty states
- `aria-label`, `title` attributes on mood/icon buttons
- Weekday names (if generated server-side and injected, check server.js too)

### 2. JS: user-facing strings
- Error messages (`saveError.textContent = '...'`)
- `confirm()` dialogs, `alert()` messages
- Progress messages (batch processing status)
- Empty-state placeholders rendered via `.innerHTML` templates
- Button text injected by JS (edit panel "Save"/"Cancel"/"Edit"/"Del")
- Note labels ("── Notes ──", "Add a note...")
- Search everywhere: `.textContent = '...'`, `innerHTML`, `confirm('...')`, `alert('...')`

### 3. Server: API validation values
- Category names in `VALID_CATEGORIES` array
- Dimension values in `TAG_DIMENSIONS` objects
- These are DATA VALUES, not just display labels. Changing them means:
  - Old stored data with old values will FAIL validation
  - New data will be stored with new values

### 4. Server: API error messages
- Every `res.status(xxx).json({ error: '...' })` string
- Export header text (`# My Diary Export`, `Exported at:`)
- Console startup log message

### 5. Server: AI prompts (if LLM integration exists)
- System prompt sent to the LLM — must ask for output in the new language's
  expected values
- If the AI was asked to output Chinese tags but the server now validates
  English, the AI MUST be re-prompted to output English

### 6. CSS: class names that encode language
- `.cat-文案灵感` → `.cat-copy-sparks`
- Any selector that uses a hardcoded language-specific string
- Search the CSS file for non-ASCII characters

### 7. Data migration
- Existing JSON data files (songs.json, fragments.json) may have stored
  values in the old language
- Write a Python migration script with a dict mapping old→new values
- Use `execute_code` to run it — keeps the migration logic visible
- Verify a few records after migration

## Migration script pattern

```python
import json

tag_map = {
    '旧值1': 'new-value-1',
    '旧值2': 'new-value-2',
}

with open('data/playlist/songs.json', 'r', encoding='utf-8') as f:
    songs = json.load(f)

count = 0
for song in songs:
    for dim, val in song.get('tags', {}).items():
        if val in tag_map:
            song['tags'][dim] = tag_map[val]
            count += 1

with open('data/playlist/songs.json', 'w', encoding='utf-8') as f:
    json.dump(songs, f, ensure_ascii=False, indent=2)

print(f'Migrated {count} values across {len(songs)} records')
```

## Verification

After completing all 7 layers:
1. Restart the server
2. `curl` the main page — grep for old-language strings (should return empty)
3. `curl` each API endpoint — verify responses use new-language values
4. Test a write operation — verify new-language validation accepts new values
5. Test a read of migrated data — verify old values were translated
