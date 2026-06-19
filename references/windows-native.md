# Windows Native — differences from WSL

When the user's environment is **native Windows** (Node.js installed directly on Windows, no WSL involved), the following WSL-specific concerns go away and are replaced by simpler Windows-native equivalents.

## What to SKIP

| WSL concern | Why skip on native Windows |
|---|---|
| Binding to `0.0.0.0` | Not needed — `localhost` works fine because the browser and Node are on the same OS |
| WSL networking mode (mirrored / NAT) | Doesn't exist |
| CIFS mount latency (`/mnt/` drives) | Native NTFS, no I/O penalty |
| `bash -c` non-interactive PATH issues | Not running through WSL; `node` is on Windows PATH |
| `pkill` / Linux process management | Use `taskkill` instead |
| `wsl -d Ubuntu -- bash -c "..."` launcher pattern | Use direct `node server.js` in `.bat` |

## What CHANGES

### start.bat
```bat
@echo off
echo Starting server...
start "MyTool" /min node server.js
timeout /t 2 /nobreak >nul
start http://localhost:3000
echo Browser opened: http://localhost:3000
pause
```
No WSL invocation needed — just `node server.js` directly. The `/min` flag starts the server window minimized.

### stop.bat
```bat
@echo off
taskkill /F /IM node.exe /T 2>nul
echo Server stopped.
pause
```
Uses `taskkill` instead of `pkill`.

### server.js — listen address
```js
app.listen(PORT, () => {
  console.log(`Ready → http://localhost:${PORT}`);
});
```
`localhost` (or just omitting the host) is fine. No need for `"0.0.0.0"`.

## What stays THE SAME

Everything else is identical:
- Express + static HTML architecture
- `.env` API key management (dotenv works the same)
- All pitfall: `.bat` file association, `file://` double-click, `.env` not read after restart
- LLM prompt patterns, API proxy pattern
- All CSS/visual references — CSS doesn't care about the OS
- Testing workflow, PLAN-driven gap analysis
- Multi-page SPA patterns (tabs, sidebar, accordion)
