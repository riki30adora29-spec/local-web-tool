# Verification Testing Workflow for Local Web Tools

After building a local web app (Express + static frontend), run this full verification sequence before declaring it done. Start the server in background first:

```bash
cd /path/to/project && npm start &
sleep 2
```

## Layer 1: Server reachability

```bash
# Frontend page loads
curl -s http://localhost:$PORT | head -5

# API returns expected shape (even empty)
curl -s http://localhost:$PORT/api/entries
```

## Layer 2: CRUD cycle

```bash
# Create (PUT with valid payload)
curl -s -X PUT http://localhost:$PORT/api/entries/$DATE \
  -H 'Content-Type: application/json' \
  -d '{"field1":"value1","field2":"value2"}'

# Read back (GET by ID)
curl -s http://localhost:$PORT/api/entries/$DATE

# Update (PUT again, verify immutable fields preserved)
curl -s -X PUT http://localhost:$PORT/api/entries/$DATE \
  -H 'Content-Type: application/json' \
  -d '{"field1":"updated","field2":"updated"}'
# → verify created_at unchanged, updated_at changed

# Read back to confirm update
curl -s http://localhost:$PORT/api/entries/$DATE

# Verify on-disk file matches
cat data/entries/$DATE.json
```

## Layer 3: Boundary / error cases

```bash
# Invalid inputs → 400
curl -s http://localhost:$PORT/api/entries/bad-format       # bad date/ID format
curl -s -X PUT ... -d '{"field":"invalid"}'                  # invalid field value
curl -s -X PUT ... -d '{"field":""}'                         # empty required field

# Not found → 404
curl -s http://localhost:$PORT/api/entries/2000-01-01

# Verify each returns proper error JSON, not a crash/stack trace
```

## Layer 4: Collection / export endpoints

```bash
# List endpoint returns metadata only (no full content)
curl -s http://localhost:$PORT/api/entries
# → verify shape matches spec (e.g., date+mood only, no content)

# Export endpoint
curl -sI http://localhost:$PORT/api/export | grep -E 'Content-(Type|Disposition)'
# → verify Content-Type and attachment filename

curl -s http://localhost:$PORT/api/export
# → verify content format, sort order, separators
```

## Layer 5: DELETE operations (if implemented)

```bash
# Delete an existing item
curl -s -X DELETE http://localhost:$PORT/api/entries/$DATE

# Verify it's gone (should return 404)
curl -s http://localhost:$PORT/api/entries/$DATE
# → {"error":"该日期无记录"}

# Delete a non-existing item → 404
curl -s -X DELETE http://localhost:$PORT/api/entries/2000-01-01
# → verify proper 404, not a crash

# Re-verify list endpoint doesn't include the deleted item
curl -s http://localhost:$PORT/api/entries | grep -c "$DATE"
# → should be 0
```

## Layer 6: Cleanup

```bash
# Remove test data so user starts with a clean slate
rm data/entries/*.json

# Kill the background server
kill %1
```

## When to run

- After every local web tool build, before telling the user it's done
- When the user reports a bug — reproduce with curl first before touching code
- After modifying any API endpoint

## Why this matters

This catches:
- Validation logic gaps (e.g., accepting invalid moods, crashing on empty content)
- Spec mismatches (e.g., list endpoint returning full content instead of metadata)
- Sort order errors (ascending vs descending)
- Immutable field leaks (created_at changing on update when it shouldn't)
- File persistence issues (disk file not matching API response)
- Export format violations (wrong headers, wrong markdown structure)
